defmodule Raftex do
  use Application

  import Logger
  import Supervisor.Spec

  @default_number_of_nodes 5

  def start(_type, _args) do
    debug "Starting #{__MODULE__}"
    import Supervisor.Spec

    children = [
      supervisor(Distributor, [])
    ]

    opts = [strategy: :one_for_one, name: Raftex.Supervisor]
    Supervisor.start_link(children, opts)
  end


  def run do
    Distributor.start(@default_number_of_nodes)
  end

end
