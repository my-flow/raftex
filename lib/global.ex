defmodule Global do

    def append_entries(term, _leaderPid, prevLogIndex, prevLogTerm, _logEntries, _leaderCommit, stateData = %StateData{}) do

        success = term >= stateData.currentTerm && 
            Enum.at(stateData.log, prevLogIndex)[:term] == prevLogTerm

        # TODO
        # 3. if an existing entry conflicts with a new one, same index but different terms), delete the
        # existing entry and all that follow it

        # TODO
        # 4. Append any new entries not already in the log

        # TODO
        # 5. If leaderCommit > commitIndex, set commitIndex = min(leaderComimt, index of last new entry)

        # TODO reply {myTerm, success}

        {:next_state, :follower, stateData, TimeHelper.generate_random_election_timeout} 
    end
end
