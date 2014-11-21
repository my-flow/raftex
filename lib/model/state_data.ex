defmodule StateData do

    defstruct [
        name: nil,
        allServers: [],
        currentTerm: 0,
        votedFor: nil,
        log: [],
        voteCount: 0,
        commitIndex: 0,
        lastApplied: 0,
        nextIndex: [],
        matchIndex: [],
        stateMachine: nil,
        leaderPid: nil,
        replicationCount: 0
    ]

end
