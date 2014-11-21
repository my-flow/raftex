defmodule Candidate do

    import DebugHelper

    def process_vote_response(voteGranted, stateData) do
        voteCount = stateData.voteCount + if voteGranted do 1 else 0 end
        majority = div(1 + Enum.count(stateData.allServers), 2) + 1
        t(stateData, :candidate, "#{inspect voteCount} of #{inspect majority} required votes")

        newStateData = %StateData{stateData | :voteCount => voteCount}
        if (voteCount >= majority) do
            :gen_fsm.send_event(self, :send_append_entries)
            {:next_state, :leader, newStateData}
        else
            {:next_state, :candidate, newStateData, TimeHelper.generate_random_election_timeout}
        end
    end


    def send_append_entries(_, stateData) do
        t(stateData, :candidate, "Ignoring request to append entries.")
        {:next_state, :candidate, stateData}
    end
end
