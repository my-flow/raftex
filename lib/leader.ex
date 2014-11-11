import Logger


defmodule Leader do

    def send_append_entries(stateData = %StateData{}) do
        Logger.info("#{inspect self}: Sending out append entries (heartbeats) to all servers")
        Enum.each(
            stateData.allServers,
            &Server.append_entries(
                &1,
                stateData.currentTerm,
                self,
                Enum.count(stateData.log),
                List.last(stateData.log)[:term],
                [],
                stateData.commitIndex
            )
        )
        :gen_fsm.send_event_after(TimeHelper.get_heartbeat_frequency, :send_append_entries)
        {:next_state, :leader, stateData}
    end


    def receive_vote(_term, _voteGranted, stateData = %StateData{}) do
        Logger.debug("#{inspect self}: Ignoring incoming vote result.")
        {:next_state, :leader, stateData}
    end
end
