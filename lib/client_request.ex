# These functions are used by both, followers and candidates.

defmodule ClientRequest do

    import DebugHelper


    def serve_client_request(command, _, stateName, stateData) when is_function(command) do
        t(stateData, stateName, "Redirecting incoming client request #{inspect command}.")
        {:reply, {:noleader, stateData.leaderPid}, stateName, stateData}
    end


    def append_entries(term, leaderPid, prevLogIndex, prevLogTerm, entries, leaderCommit, from, stateName, stateData) do

        newStateData = %{stateData | :leaderPid => leaderPid}

        if entries && !Enum.empty?(entries)  do

            success = true

            if prevLogIndex >= 0 do
                success = term >= newStateData.currentTerm && 
                    Enum.at(newStateData.log, prevLogIndex) != nil &&
                    Enum.at(newStateData.log, prevLogIndex).term == prevLogTerm
            end

            # TODO
            # 3. if an existing entry conflicts with a new one, same index but different terms), delete the
            # existing entry and all that follow it

            newStateData = %{newStateData | :log => newStateData.log ++ entries}

            Server.receive_replication_ack(leaderPid, term, success, leaderCommit, from)
        end

        if leaderCommit > newStateData.commitIndex do
            newStateData = %{newStateData | :commitIndex => min(leaderCommit, Enum.count(newStateData.log) - 1)}
        end

        {:next_state, stateName, newStateData, TimeHelper.generate_random_election_timeout} 
    end
end
