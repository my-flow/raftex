# These functions are used by both, followers and candidates.

defmodule Election do

    import DebugHelper


    def timeout(stateName, stateData) do
        t(stateData, stateName, "election timeout")

        newStateData = %StateData{stateData | :currentTerm => stateData.currentTerm + 1}
        t(stateData, stateName, "incrementing current term to #{newStateData.currentTerm}")

        newStateData = %StateData{newStateData | :votedFor => stateData.name, :voteCount => 1}
        t(newStateData, stateName, "voting for itself")

        t(newStateData, stateName, "sending out vote requests to other nodes")
        Enum.each(
            newStateData.allServers,
            &Server.request_vote(&1, newStateData.currentTerm, stateData.name, Enum.count(newStateData.log), List.last(newStateData.log)[:term])
        )
        t(newStateData, stateName, "transitioning to candidate state")
        {:next_state, :candidate, newStateData, TimeHelper.generate_random_election_timeout}
    end


    def request_vote(term, candidateName, lastLogIndex, lastLogTerm, stateName, stateData) do
        t(stateData, stateName, "Received incoming request to vote for #{inspect candidateName}")

        myLastLogIndex = Enum.count(stateData.log)
        myLastLogTerm  = List.last(stateData.log)[:term]

        newStateData = stateData
        if term < stateData.currentTerm do
            voteGranted = false
        else
            if (stateData.votedFor == nil || stateData.votedFor == candidateName) && 
                lastLogIndex >= myLastLogIndex && lastLogTerm  >= myLastLogTerm do

                voteGranted = true
                newStateData = %StateData{stateData | :votedFor => candidateName}
            else
                voteGranted = false
            end
        end

        Server.receive_vote(:global.whereis_name(String.to_atom to_string candidateName), stateData.currentTerm, voteGranted)
        {:next_state, stateName, newStateData, TimeHelper.generate_random_election_timeout}
    end
end
