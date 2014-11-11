RaftEx
======

An implementation of the [Raft Consensus Algorithm](https://raftconsensus.github.io) in Elixir/Erlang using distributed finite state machines (`gen_fsm`).

## What is Consensus / what is Raft?

From the [official website](https://raftconsensus.github.io):

> Consensus is a fundamental problem in fault-tolerant distributed systems. Consensus involves multiple servers agreeing on values. (…) Raft is a consensus algorithm that is designed to be easy to understand. It's equivalent to Paxos in fault-tolerance and performance. The difference is that it's decomposed into relatively independent subproblems, and it cleanly addresses all major pieces needed for practical systems.


## Installation

1. Clone the repository with `git clone git@github.com:my-flow/raftex.git`.
2. Install the required dependencies with `mix deps.get`.
3. Start Elixir's interactive shell with `iex -S mix`.
4. Run a simulation with 5 distributed nodes: `iex(1)> RaftEx.run`


## Copyright & License

Copyright (c) 2014 [Florian J. Breunig](http://www.my-flow.com)

Licensed under MIT, see LICENSE file.
