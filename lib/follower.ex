defmodule Follower do

    import DebugHelper

    def receive_vote(_term, _voteGranted, stateData) do
        d(stateData, :follower, "Ignoring incoming vote result.")
        {:next_state, :follower, stateData}
    end


    def send_append_entries(stateData) do
        d(stateData, :follower, "Ignoring request to append entries.")
        {:next_state, :follower, stateData}
    end
end
