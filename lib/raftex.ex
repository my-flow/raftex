defmodule RaftEx do
  use Application


  # Initialization

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Distributor, [], [])
    ]

    opts = [strategy: :simple_one_for_one, name: RaftEx.Supervisor]
    Supervisor.start_link(children, opts)
  end


  # Run

  def run do
    Supervisor.start_child(RaftEx.Supervisor, [])
  end

end
