defmodule Leader do

    import DebugHelper

    def send_append_entries(stateData) do
        t(stateData, :leader, "Sending out append entries (heartbeats) to all servers")
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


    def receive_vote(_term, _voteGranted, stateData) do
        t(stateData, :leader, "Ignoring incoming vote result.")
        {:next_state, :leader, stateData}
    end
end
