# These functions are used by both, followers and candidates.

defmodule Election do

    import DebugHelper


    def timeout(stateName, stateData) do
        i(stateData, stateName, "election timeout")

        newStateData = %StateData{stateData | :currentTerm => stateData.currentTerm + 1}
        i(stateData, stateName, "incrementing current term to #{newStateData.currentTerm}")

        newStateData = %StateData{newStateData | :votedFor => self, :voteCount => 1}
        i(newStateData, stateName, "voting for itself")

        i(newStateData, stateName, "sending out vote requests to other nodes")
        Enum.each(
            newStateData.allServers,
            &Server.request_vote(&1, newStateData.currentTerm, self, Enum.count(newStateData.log), List.last(newStateData.log)[:term])
        )
        i(newStateData, stateName, "transitioning to candidate state")
        {:next_state, :candidate, newStateData, TimeHelper.generate_random_election_timeout}
    end


    def request_vote(term, candidatePid, lastLogIndex, lastLogTerm, stateName, stateData) do
        d(stateData, stateName, "Received incoming request to vote for #{inspect candidatePid}")

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
        {:next_state, stateName, newStateData, TimeHelper.generate_random_election_timeout}
    end
end
