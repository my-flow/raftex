# These functions are used by both, followers and candidates.

defmodule Election do

    import DebugHelper


    def timeout(stateName, stateData) do
        t(stateData, stateName, "election timeout")

        newStateData = %StateData{stateData | :currentTerm => stateData.currentTerm + 1}
        t(stateData, stateName, "incrementing current term to #{newStateData.currentTerm}")

        newStateData = %StateData{newStateData | :votedFor => stateData.name, :voteCount => 1}

        Enum.each(
            newStateData.allServers,
            &Server.send_vote(
                &1,
                newStateData.currentTerm,
                stateData.name,
                Enum.count(newStateData.log),
                case List.last(newStateData.log) do
                    nil -> nil
                    entry -> entry.term
                end
            )
        )
        t(newStateData, stateName, "transitioning to candidate state")
        {:next_state, :candidate, newStateData, TimeHelper.generate_random_election_timeout}
    end


    def send_vote(term, candidateName, lastLogIndex, lastLogTerm, stateName, stateData) do
        t(stateData, stateName, "Received incoming request to vote for #{inspect candidateName}")

        myLastLogIndex = Enum.count(stateData.log)
        myLastLogTerm  = case List.last(stateData.log) do 
            nil   -> nil
            entry -> entry.term
        end

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

        Server.process_vote_response(candidateName, stateData.currentTerm, voteGranted)
        {:next_state, stateName, newStateData, TimeHelper.generate_random_election_timeout}
    end
end
