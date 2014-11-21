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
                case List.last(stateData.log) do
                    nil -> nil
                    entry -> entry.term
                end,
                [], # empty for heartbeats
                stateData.commitIndex,
                nil
            )
        )
        :gen_fsm.send_event_after(TimeHelper.get_heartbeat_frequency, :send_append_entries)
        {:next_state, :leader, stateData}
    end


    def process_vote_response(_term, _voteGranted, stateData) do
        t(stateData, :leader, "Ignoring incoming vote result.")
        {:next_state, :leader, stateData}
    end


    def serve_client_request(command, from, _, stateData) when is_function(command) do
        t(stateData, :leader, "Sending out append entries #{inspect command} to all servers")

        entry = %LogEntry{:command => command, :term => stateData.currentTerm}
        newStateData = %{stateData | :replicationCount => 1, :log => stateData.log ++ [entry]}

        prevLogIndex = Enum.count(newStateData.log) - 2
        Enum.each(
            newStateData.allServers,
            &Server.append_entries(
                &1,
                newStateData.currentTerm,
                self,
                prevLogIndex,
                if prevLogIndex >= 0 do Enum.at(newStateData.log, prevLogIndex).term else nil end,
                [entry],
                newStateData.commitIndex,
                from
            )
        )
        {:next_state, :leader, newStateData}
    end


    def receive_replication_ack(success, leaderCommit, from, stateData) do
        replicationCount = stateData.replicationCount + if success do 1 else 0 end
        majority = div(1 + Enum.count(stateData.allServers), 2) + 1
        t(stateData, :leader, "#{inspect replicationCount} of #{inspect majority} servers have replicated the change")

        newStateData = %StateData{stateData | :replicationCount => replicationCount}
        if (replicationCount == majority) do
            command = Enum.at(newStateData.log, newStateData.commitIndex).command
            reply = StateMachine.apply(newStateData.stateMachine, command)
            newStateData = %{newStateData |
                :commitIndex => newStateData.commitIndex + 1,
                :lastApplied => newStateData.lastApplied + 1
            }
            t(stateData, :leader, "Command #{inspect command} was committed successfully.") # TODO
            t(stateData, :leader, "Sending reply #{inspect reply} to client.")
            :gen_fsm.reply(from, reply)
        end
        {:next_state, :leader, newStateData}
    end

end
