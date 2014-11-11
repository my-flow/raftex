import Logger


defmodule Server do

    # Initialization

    def start_link(name) do
        :gen_fsm.start_link(__MODULE__, [name], [])
    end


    def init(name) do
        Logger.info "Starting #{inspect __MODULE__} #{name}"
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


    def receive_vote(pid, term, voteGranted) do
        :gen_fsm.send_event(pid, {:receive_vote, term, voteGranted})
    end


    # global events

    def request_vote(pid, term, candidatePid, lastLogIndex, lastLogTerm) do
        :gen_fsm.send_all_state_event(pid, {:request_vote, term, candidatePid, lastLogIndex, lastLogTerm})
    end


    def append_entries(pid, term, leaderPid, prevLogIndex, prevLogTerm, logEntries, leaderCommit) do
        :gen_fsm.send_all_state_event(
            pid,
            {:append_entries, term, leaderPid, prevLogIndex, prevLogTerm, logEntries, leaderCommit}
        )
    end


    def terminate(reason, state, _) do
        Logger.warn("#{inspect self}: #{inspect state} terminating with reason #{inspect reason}")
    end    


    # follower callbacks

    def follower(:timeout, stateData) do
        Follower.timeout(stateData)
    end


    # candidate callbacks

    def candidate(:timeout, stateData) do
        Follower.timeout(stateData) # candidate should NOT call the follower module 
    end


    def candidate(:start_election, stateData) do
        Candidate.start_election(stateData)
    end


    def candidate({:receive_vote, term, voteGranted}, stateData) do
        RuleHelper.check_for_outdated_term(term, stateData, &Candidate.receive_vote(term, voteGranted, &1))
    end


    # leader callbacks

    def leader(:send_append_entries, stateData) do
        Leader.send_append_entries(stateData)
    end


    def leader({:receive_vote, term, voteGranted}, stateData = %StateData{}) do
        RuleHelper.check_for_outdated_term(term, stateData, &Leader.receive_vote(term, voteGranted, &1))
    end


    # global events

    def handle_sync_event({:propagate, servers}, _, stateName, stateData = %StateData{}) do
        newStateData = %StateData{stateData | :allServers => servers}
        {:reply, :ok, stateName, newStateData}
    end


    def handle_event(:resume, stateName, stateData) do
        election_timeout = TimeHelper.generate_random_election_timeout
        Logger.debug("#{inspect self}: random election timeout: #{inspect election_timeout}")
        {:next_state, :follower, stateData, election_timeout}
    end


    def handle_event(
        {:request_vote, term, candidatePid, lastLogIndex, lastLogTerm},
        stateName, stateData = %StateData{}) do

        Logger.debug "#{inspect self}: Received incoming request to vote for #{inspect candidatePid}"

        myLastLogIndex = Enum.count(stateData.log)
        myLastLogTerm  = List.last(stateData.log)[:term]

        newStateData = stateData
        if term < stateData.currentTerm do
            voteGranted = false
        else
            if (stateData.votedFor == nil || stateData.votedFor == candidatePid) && 
                lastLogIndex >= myLastLogIndex && lastLogTerm  >= myLastLogTerm do

                voteGranted = true
                newStateData = %StateData{stateData | :votedFor => candidatePid}
            else
                voteGranted = false
            end
        end

        Server.receive_vote(candidatePid, stateData.currentTerm, voteGranted)
        {:next_state, stateName, newStateData} 
    end


    def handle_event(
        {:append_entries, term, _leaderPid, prevLogIndex, prevLogTerm, _logEntries, _leaderCommit},
        stateName, stateData = %StateData{}) do

        f = fn(stateData) ->
            Global.append_entries(term, _leaderPid, prevLogIndex, prevLogTerm, _logEntries, _leaderCommit, stateData)
        end

        RuleHelper.check_for_outdated_term(term, stateData, f)
    end

end
