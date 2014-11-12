defmodule Follower do

    import DebugHelper

    def receive_vote(_term, _voteGranted, stateData) do
        d(stateData, :follower, "Ignoring incoming vote result.")
        {:next_state, :follower, stateData}
    end
end
