defmodule Distributor do
  use ExActor.Strict, export: {:global, :Distributor}

  import Logger

  @number_of_nodes 5


  # Initialization

  def start_link do
    debug "Starting #{__MODULE__}"
    import Supervisor.Spec, warn: false

    children = [
      worker(Server, [], restart: :temporary)
    ]

    opts = [strategy: :simple_one_for_one, name: {:global, RaftEx.Supervisor}]
    Supervisor.start_link(children, opts)
  end


  # Launch

  def run do
    pids = for i <- 1..@number_of_nodes do
      {:ok, pid} = Supervisor.start_child({:global, RaftEx.Supervisor}, [to_string i])
      pid
    end

    for pid <- pids, do: Server.propagate(pid, Enum.filter(pids, &(&1 != pid)))

    Enum.each(pids, &Server.resume(&1))
  end


  # Manipulate the nodes

  def kill_leaders do
    matches =
      Enum.filter(get_children_pids, &({stateName, _} = :sys.get_state(&1)) && stateName == :leader) |>  
      Enum.map(&Process.exit(&1, :kill)) |> Enum.count

    case matches do
      0 -> :error
      _ -> :ok
    end
  end


  def kill_any_follower do
    first = Enum.find(get_children_pids, &({stateName, _} = :sys.get_state(&1)) && stateName == :follower)
    case first do
      nil -> :error
      pid -> Process.exit(pid, :kill) && :ok
    end
  end


  defp get_children_pids do
    Enum.map(Supervisor.which_children({:global, RaftEx.Supervisor}), fn {_, pid, _, _} -> pid end)
  end

end
