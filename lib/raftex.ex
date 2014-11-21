defmodule Raftex do
  use Application

  import Logger
  import Supervisor.Spec


  def start(_type, _args) do
    debug "Starting #{__MODULE__}"
    import Supervisor.Spec

    children = [
      supervisor(Distributor, [], restart: :transient)
    ]

    opts = [strategy: :simple_one_for_one, name: Raftex.Supervisor]
    Supervisor.start_link(children, opts)
  end


  def run(name, number_of_nodes \\ 5) do
    {:ok, pid} = Supervisor.start_child(Raftex.Supervisor, [[name: name]])
    Distributor.start(pid, number_of_nodes)
    pid
  end

end
