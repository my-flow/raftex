import Logger


defmodule Server do

    # Initialization

    def start_link(name) do
        :gen_fsm.start_link(__MODULE__, [name], [])
    end


    def init(name) do
        Logger.info "Starting #{inspect __MODULE__} #{name}"
        :random.seed(:erlang.now)
        {:ok, :follower, %StateData{:persistent => %Persistent{}, :volatile => %Volatile{}}}
    end


    def propagate(pid, servers) do
        :gen_fsm.sync_send_all_state_event(pid, {:propagate, servers})
    end


    # behaviour functions

    def resume(pid) do
        :gen_fsm.sync_send_all_state_event(pid, :resume)
    end


    def heartbeat(pid) do
        :gen_fsm.send_event(pid, :heartbeat)
    end


    # global events

    def request_vote(pid, term, lastLogIndex, lastLogTerm) do
        :gen_fsm.sync_send_all_state_event(pid, {:request_vote, term, lastLogIndex, lastLogTerm})
    end


    def terminate(reason, state, _) do
        Logger.warn("#{inspect self}: #{inspect state} terminating with reason #{inspect reason}")
    end    


    # follower callbacks

    def follower(:timeout, stateData = %StateData{:persistent => persistent = %Persistent{:currentTerm => currentTerm}}) do
        Logger.info("#{inspect self}: election timeout")
        Logger.info("#{inspect self}: incrementing current term from #{currentTerm} to #{currentTerm + 1}")
        newStateData = %StateData{stateData | :persistent => %Persistent{persistent | :currentTerm => currentTerm + 1}}

        Logger.info("#{inspect self}: transitioning from follower state to candidate state")
        :gen_fsm.send_event_after(0, :start_election)

        {:next_state, :candidate, newStateData}
    end


    def follower(:heartbeat, stateData) do
        {:next_state, :follower, stateData, TimeHelper.get_heartbeat_timeout}
    end


    # candidate callbacks

    def candidate(:start_election, stateData) do
        Logger.info("#{inspect self}: election timeout, start new election, state: #{inspect stateData}")
        newState = Candidate.start_election(stateData)
        if (newState == :leader) do
            :gen_fsm.send_event_after(0, :send_heartbeat_messages)
            {:next_state, newState, stateData}
        else
            {:next_state, newState, stateData, TimeHelper.generate_random_election_timeout}
        end
    end


    def candidate(:heartbeat, stateData) do
        {:next_state, :follower, stateData, TimeHelper.get_heartbeat_timeout}
    end


    # leader callbacks

    def leader(:send_heartbeat_messages, stateData = %StateData{persistent: %Persistent{:allServers => allServers}}) do
        Logger.info("#{inspect self}: Sending out heartbeat messages to all servers")
        Enum.each(allServers, &Server.heartbeat(&1))
        :gen_fsm.send_event_after(TimeHelper.get_heartbeat_frequency, :send_heartbeat_messages)
        {:next_state, :leader, stateData}
    end


    # global events

    def handle_sync_event(:resume, _, _, stateData) do
        election_timeout = TimeHelper.generate_random_election_timeout
        Logger.debug("#{inspect self}: random election timeout: #{inspect election_timeout}")
        {:reply, :ok, :follower, stateData, election_timeout}
    end


    def handle_sync_event({:propagate, servers}, _, stateName,
        stateData = %StateData{:persistent => persistent}) do

        newStateData = %StateData{stateData | :persistent => %Persistent{persistent | :allServers => servers}}
        {:reply, :ok, stateName, newStateData}
    end


    def handle_sync_event({:request_vote, term, lastLogIndex, lastLogTerm}, {from, _}, stateName,
        stateData = %StateData{:persistent => %Persistent{:currentTerm => myTerm, :votedFor => myVotedFor, :log => log}}) do

        Logger.debug "#{inspect self}: Received incoming request to vote for #{inspect from}"

        myLastLogIndex = Enum.count(log)
        myLastLogTerm  = List.last(log)[:term]

        if term < myTerm do
            rVoteGranted = false
        else
            rVoteGranted =
                if (myVotedFor == nil || myVotedFor == from) && 
                    lastLogIndex >= myLastLogIndex && lastLogTerm  >= myLastLogTerm do
                    true
                else
                    false
                end
        end

        {:reply, {myTerm, rVoteGranted}, stateName, stateData} 
    end
end
