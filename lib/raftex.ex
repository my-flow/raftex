defmodule Raftex do
  use Application

  import Logger
  import Supervisor.Spec


  def start(_type, _args) do
    debug "Starting #{__MODULE__}"
    import Supervisor.Spec

    children = []

    opts = [strategy: :one_for_one, name: Raftex.Supervisor]
    Supervisor.start_link(children, opts)
  end


  def run do
    Supervisor.start_child(Raftex.Supervisor, supervisor(Distributor, []))
    Distributor.run
  end

end
