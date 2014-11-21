defmodule Server do

    import Logger
    import DebugHelper


    # Initialization

    def start_link(name) do
        :gen_fsm.start_link(name, __MODULE__, name, [])
    end


    def init(name) do
        info "Starting #{inspect __MODULE__} #{inspect name}"
        :random.seed(:erlang.now)
        {:ok, pid} = StateMachine.start_link
        {:ok, :follower, %StateData{:name => name, :stateMachine => pid}}
    end


    def propagate(pid, servers) do
        :gen_fsm.sync_send_all_state_event(pid, {:propagate, servers})
    end


    # behaviour functions

    def resume(pid) do
        :gen_fsm.send_all_state_event(pid, :resume)
    end


    def send_vote(pid, term, candidatePid, lastLogIndex, lastLogTerm) do
        :gen_fsm.send_event(pid, {:send_vote, term, candidatePid, lastLogIndex, lastLogTerm})
    end


    def process_vote_response(pid, term, voteGranted) do
        :gen_fsm.send_event(pid, {:process_vote_response, term, voteGranted})
    end


    def serve_client_request(pid, command) do
        :gen_fsm.sync_send_event(pid, {:serve_client_request, command})
    end


    def receive_replication_ack(pid, term, success, leaderCommit, from) do
        :gen_fsm.send_event(pid, {:receive_replication_ack, term, success, leaderCommit, from})
    end


    # global events

    def append_entries(pid, term, leaderPid, prevLogIndex, prevLogTerm, entries, leaderCommit, from) do
        :gen_fsm.send_all_state_event(
            pid,
            {:append_entries, term, leaderPid, prevLogIndex, prevLogTerm, entries, leaderCommit, from}
        )
    end


    def terminate(reason, _, stateData) do
        t(stateData, "terminating with reason #{inspect reason}")
    end


    # follower callbacks

    def follower(:timeout, stateData) do
        Election.timeout(:follower, stateData)
    end


    def follower({:send_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.send_vote(term, candidatePid, lastLogIndex, lastLogTerm, :follower, &1)
        )
    end

    def follower({:process_vote_response, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Follower.process_vote_response(term, voteGranted, &1))
    end


    def follower(:send_append_entries, stateData) do
        Follower.send_append_entries(stateData)
    end


    def follower({:serve_client_request, command}, from, stateData) do
        ClientRequest.serve_client_request(command, from, :follower, stateData)
    end


    # candidate callbacks

    def candidate(:timeout, stateData) do
        Election.timeout(:candidate, stateData)
    end


    def candidate({:send_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.send_vote(term, candidatePid, lastLogIndex, lastLogTerm, :candidate, &1)
        )
    end


    def candidate({:process_vote_response, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Candidate.process_vote_response(voteGranted, &1))
    end


    def candidate(:send_append_entries, stateData) do
        Candidate.send_append_entries(stateData)
    end


    def candidate({:serve_client_request, command}, from, stateData) do
        ClientRequest.serve_client_request(command, from, :candidate, stateData)
    end


    # leader callbacks

    def leader({:send_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.send_vote(term, candidatePid, lastLogIndex, lastLogTerm, :leader, &1)
        )
    end


    def leader({:process_vote_response, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Leader.process_vote_response(term, voteGranted, &1))
    end


    def leader(:send_append_entries, stateData) do
        Leader.send_append_entries(stateData)
    end


    def leader({:serve_client_request, command}, from, stateData) do
        Leader.serve_client_request(command, from, :leader, stateData)
    end


    def leader({:receive_replication_ack, term, success, leaderCommit, from}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Leader.receive_replication_ack(success, leaderCommit, from, &1))
    end


    # global events

    def handle_sync_event({:propagate, servers}, _, stateName, stateData) do
        newStateData = %StateData{stateData | :allServers => servers}
        {:reply, :ok, stateName, newStateData}
    end


    def handle_event(:resume, stateName, stateData) do
        t(stateData, stateName, "Resuming node")
        {:next_state, :follower, stateData, TimeHelper.generate_random_election_timeout}
    end


    def handle_event(
        {:append_entries, term, leaderPid, prevLogIndex, prevLogTerm, entries, leaderCommit, from},
        stateName, stateData) do

        f = fn(stateData) ->
            ClientRequest.append_entries(term, leaderPid, prevLogIndex, prevLogTerm, entries, leaderCommit, from, stateName, stateData)
        end

        RuleHelper.check_for_outdated_term(term, stateData, f)
    end
end
