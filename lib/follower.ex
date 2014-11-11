import Logger


defmodule Follower do

    def timeout(stateData = %StateData{}) do
        Logger.info("#{inspect self}: election timeout")
        Logger.info("#{inspect self}: incrementing current term from #{stateData.currentTerm} to #{stateData.currentTerm + 1}")
        newStateData = %StateData{stateData | :currentTerm => stateData.currentTerm + 1}

        Logger.info("#{inspect self}: transitioning from follower state to candidate state")
        :gen_fsm.send_event_after(0, :start_election)

        {:next_state, :candidate, newStateData}
    end
end