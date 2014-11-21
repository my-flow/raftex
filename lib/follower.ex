defmodule Follower do

    import DebugHelper

    def process_vote_response(_term, _voteGranted, stateData) do
        t(stateData, :follower, "Ignoring incoming vote result.")
        {:next_state, :follower, stateData}
    end


    def send_append_entries(_, stateData) do
        t(stateData, :follower, "Ignoring request to append entries.")
        {:next_state, :follower, stateData}
    end
end
