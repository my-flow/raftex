defmodule Distributor do
  use ExActor.Strict

  import Logger
  import Supervisor.Spec


  # Initialization

  defstart start_link(args), gen_server_opts: args do
    debug "Starting #{__MODULE__}"

    children = [
      worker(Server, [], restart: :temporary)
    ]
    opts = [strategy: :simple_one_for_one]
    {:ok, sup} = Supervisor.start_link(children, opts)

    initial_state {sup, nil}
  end


  # Launch

  defcall start(number_of_nodes), when: is_integer(number_of_nodes) and number_of_nodes > 0, state: {sup, _} do
    Enum.each(get_children_pids(sup), &(true = Process.exit(&1, :shutdown)))

    range = range(number_of_nodes)
    range |> Enum.each(&Supervisor.start_child(sup, [&1]))
    range |> Enum.each(&Server.propagate(&1, Enum.reject(range, fn n -> n == &1 end)))
    range |> Enum.each(&Server.resume(&1))
    set_and_reply {sup, number_of_nodes}, :ok
  end


  defcall get_number_of_nodes, state: {_, number_of_nodes} do
    reply number_of_nodes
  end


  defcall apply_command(command), when: is_function(command), state: {sup, _} do
    server = List.first(get_children_pids(sup))
    reply Server.serve_client_request(server, command)
  end


  defcall apply_command(leaderPid, command), when: is_function(command) do
    reply Server.serve_client_request(leaderPid, command)
  end


  # Manipulate the nodes

  defcall resume(number), when: is_integer(number) and number >= 1, state: {sup, number_of_nodes} do
    name = create_name_from_number(number)
    case Supervisor.start_child(sup, [name]) do
      {:ok, _} ->
        Server.propagate(name, Enum.reject(range(number_of_nodes), &(&1 == name)))
        Server.resume(name)
        reply :ok
      other ->
        reply other
    end
  end


  defcall kill_leaders, state: {sup, _} do
    case get_leaders(sup) |> Enum.map(&Process.exit(&1, :kill)) |> Enum.count do
      0 -> reply :error
      _ -> reply :ok
    end
  end


  defcall kill_any_follower, state: {sup, _} do
    first = List.first(get_followers(sup))
    case first do
      nil -> reply :error
      pid -> reply Process.exit(pid, :kill)
    end
  end


  defcall get_all_servers, state: {sup, _} do
    children = Supervisor.which_children(sup) |>
      Enum.map(fn {_, pid, _, _} -> pid end) |> Enum.map(&:sys.get_state(&1))
    reply children
  end


  defp get_leaders(sup) do
    Enum.filter(get_children_pids(sup), &({stateName, _} = :sys.get_state(&1)) && stateName == :leader)
  end


  defp get_followers(sup) do
    Enum.filter(get_children_pids(sup), &({stateName, _} = :sys.get_state(&1)) && stateName == :follower)
  end


  def range(number_of_nodes) when is_integer(number_of_nodes) and number_of_nodes > 0 do
    for i <- 1..number_of_nodes do create_name_from_number(i) end
  end


  defp create_name_from_number(number) when is_integer(number) do
    {:global, String.to_atom(to_string(number))}
  end


  defp get_children_pids(sup) do
    Enum.map(Supervisor.which_children(sup), fn {_, pid, _, _} -> pid end)
  end

end
