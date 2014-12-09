Raftex
======

An implementation of the [Raft Consensus Algorithm](https://raftconsensus.github.io) in Elixir/Erlang using distributed finite state machines (`gen_fsm`).

[![Build Status](https://travis-ci.org/my-flow/raftex.svg?branch=master)](https://travis-ci.org/my-flow/raftex)


## What is Consensus / what is Raft?

From the [official website](https://raftconsensus.github.io):

> Consensus is a fundamental problem in fault-tolerant distributed systems. Consensus involves multiple servers agreeing on values. (…) Raft is a consensus algorithm that is designed to be easy to understand. It's equivalent to Paxos in fault-tolerance and performance. The difference is that it's decomposed into relatively independent subproblems, and it cleanly addresses all major pieces needed for practical systems.


## Installation

1. Clone the repository with `git clone git@github.com:my-flow/raftex.git`.
2. Install the required dependencies with `mix deps.get`.

## Watch simulation in a browser

1. Start web server with `mix phoenix.start`
2. Open a web browser and visit URL _http://localhost:4000_

## Watch simulation in a terminal

1. Start Elixir's interactive shell with `iex -S mix`.
2. Run a simulation with 5 distributed nodes: `iex(1)> Raftex.run`

## Copyright & License

Copyright (c) 2014 [Florian J. Breunig](http://www.my-flow.com)

Licensed under MIT, see LICENSE file.
