defmodule Server do

    import Logger
    import DebugHelper

    # Initialization

    def start_link(name) do
        :gen_fsm.start_link(__MODULE__, [name], [])
    end


    def init(name) do
        info "Starting #{inspect __MODULE__} #{name}"
        :random.seed(:erlang.now)
        {:ok, :follower, %StateData{}}
    end


    def propagate(pid, servers) do
        :gen_fsm.sync_send_all_state_event(pid, {:propagate, servers})
    end


    # behaviour functions

    def resume(pid) do
        :gen_fsm.send_all_state_event(pid, :resume)
    end


    def request_vote(pid, term, candidatePid, lastLogIndex, lastLogTerm) do
        :gen_fsm.send_event(pid, {:request_vote, term, candidatePid, lastLogIndex, lastLogTerm})
    end


    def receive_vote(pid, term, voteGranted) do
        :gen_fsm.send_event(pid, {:receive_vote, term, voteGranted})
    end



    # global events

    def append_entries(pid, term, leaderPid, prevLogIndex, prevLogTerm, logEntries, leaderCommit) do
        :gen_fsm.send_all_state_event(
            pid,
            {:append_entries, term, leaderPid, prevLogIndex, prevLogTerm, logEntries, leaderCommit}
        )
    end


    def terminate(reason, _, stateData) do
        w(stateData, "terminating with reason #{inspect reason}")
    end


    # follower callbacks

    def follower(:timeout, stateData) do
        Election.timeout(:follower, stateData)
    end


    def follower({:request_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.request_vote(term, candidatePid, lastLogIndex, lastLogTerm, :follower, &1)
        )
    end

    def follower({:receive_vote, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Follower.receive_vote(term, voteGranted, &1))
    end


    # candidate callbacks

    def candidate(:timeout, stateData) do
        Election.timeout(:candidate, stateData)
    end


    def candidate(:start_election, stateData) do
        Candidate.start_election(stateData)
    end


    def candidate({:request_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.request_vote(term, candidatePid, lastLogIndex, lastLogTerm, :candidate, &1)
        )
    end


    def candidate({:receive_vote, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Candidate.receive_vote(term, voteGranted, &1))
    end


    # leader callbacks

    def leader(:send_append_entries, stateData) do
        Leader.send_append_entries(stateData)
    end


    def leader({:request_vote, term, candidatePid, lastLogIndex, lastLogTerm}, stateData) do
        RuleHelper.check_for_outdated_term(
            term,
            stateData,
            &Election.request_vote(term, candidatePid, lastLogIndex, lastLogTerm, :leader, &1)
        )
    end


    def leader({:receive_vote, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Leader.receive_vote(term, voteGranted, &1))
    end


    # global events

    def handle_sync_event({:propagate, servers}, _, stateName, stateData) do
        newStateData = %StateData{stateData | :allServers => servers}
        {:reply, :ok, stateName, newStateData}
    end


    def handle_event(:resume, stateName, stateData) do
        election_timeout = TimeHelper.generate_random_election_timeout
        d(stateData, stateName, "random election timeout: #{inspect election_timeout}")
        {:next_state, :follower, stateData, election_timeout}
    end


    def handle_event(
        {:append_entries, term, _leaderPid, prevLogIndex, prevLogTerm, _logEntries, _leaderCommit},
        _, stateData = %StateData{}) do

        f = fn(stateData) ->
            Global.append_entries(term, _leaderPid, prevLogIndex, prevLogTerm, _logEntries, _leaderCommit, stateData)
        end

        RuleHelper.check_for_outdated_term(term, stateData, f)
    end
end
