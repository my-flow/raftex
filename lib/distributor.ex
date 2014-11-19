defmodule Distributor do
  use ExActor.Strict, export: {:global, :Distributor}

  import Logger
  import Supervisor.Spec


  # Initialization

  def start_link do
    debug "Starting #{__MODULE__}"

    children = [
      worker(Server, [], restart: :temporary)
    ]

    opts = [strategy: :simple_one_for_one, name: {:global, Raftex.Distributor.Supervisor}]
    Supervisor.start_link(children, opts)
  end


  definit do
    initial_state nil
  end


  # Launch

  def start(number_of_nodes) when is_integer(number_of_nodes) and number_of_nodes > 0 do
    Enum.each(get_children_pids, &(true = Process.exit(&1, :shutdown)))

    range = 1..number_of_nodes
    range |> Enum.each(&Supervisor.start_child({:global, Raftex.Distributor.Supervisor}, [&1]))
    range |> Enum.each(
      &Server.propagate(
        create_name_from_number(&1),
        Enum.reject(range, fn n -> n == &1 end) |> Enum.map(fn n -> create_name_from_number(n) end))
      )
    range |> Enum.each(&Server.resume(create_name_from_number(&1)))
  end


  # Manipulate the nodes

  def resume(number) when is_integer(number) and number >= 1 do

    case Supervisor.start_child({:global, Raftex.Distributor.Supervisor}, [number]) do
      {:ok, _} ->
        Server.propagate(
          create_name_from_number(number),
          Enum.reject(1..Enum.count(get_children_pids), fn n -> n == number end) |> Enum.map(fn n -> create_name_from_number(n) end)
        )
        Server.resume(create_name_from_number(number))
      other ->
        other
    end
  end


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


  def get_all_servers do
    Supervisor.which_children({:global, Raftex.Distributor.Supervisor}) |>
      Enum.map(fn {_, pid, _, _} -> pid end) |> Enum.map(&:sys.get_state(&1))
  end


  defp create_name_from_number(number) when is_integer(number) do
    {:global, String.to_atom(to_string(number))}
  end


  defp get_children_pids do
    Enum.map(Supervisor.which_children({:global, Raftex.Distributor.Supervisor}), fn {_, pid, _, _} -> pid end)
  end

end
