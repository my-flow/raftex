import Logger


defmodule Candidate do

    def start_election(stateData = %StateData{}) do
        Logger.info("#{inspect self}: election timeout, start new election, state: #{inspect stateData}")
        newStateData = %StateData{stateData | :voteCount => 1}
        Enum.each(
            stateData.allServers,
            &Server.request_vote(&1, stateData.currentTerm, self, Enum.count(stateData.log), List.last(stateData.log)[:term])
        )
        {:next_state, :candidate, newStateData}
    end


    def receive_vote(term, voteGranted, stateData = %StateData{}) do
        voteCount = stateData.voteCount + if voteGranted do 1 else 0 end
        majority = div(1 + Enum.count(stateData.allServers), 2) + 1
        Logger.warn("#{inspect self}: New total: #{inspect voteCount} votes out of #{inspect majority} required")

        newStateData = %StateData{stateData | :voteCount => voteCount}
        if (voteCount >= majority) do
            :gen_fsm.send_event(self, :send_append_entries)
            {:next_state, :leader, newStateData}
        else
            {:next_state, :candidate, newStateData, TimeHelper.generate_random_election_timeout}
        end
    end
end
