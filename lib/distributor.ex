import Logger


defmodule Distributor do
  use ExActor.Strict, export: {:global, :Distributor}

  @number_of_nodes 5


  # Initialization

  definit do
    Logger.debug "Starting #{__MODULE__}"
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Server, [], restart: :temporary)
    ]

    opts = [strategy: :simple_one_for_one, name: Distributor]
    Supervisor.start_link(children, opts)
    create_and_propagate_children(@number_of_nodes)
    initial_state nil
  end


  defp create_and_propagate_children(count) do
    pids = for i <- 1..count do
      {:ok, pid} = Supervisor.start_child(Distributor, [to_string i])
      pid
    end

    for pid <- pids, do: Server.propagate(pid, Enum.filter(pids, &(&1 != pid)))

    Enum.each(pids, &Server.resume(&1))
  end


  # Manipulate the nodes

  def kill_leaders do
    # TODO
    # :sys.get_state(pid) returns {CurrentStateName, CurrentStateData}
    # see http://www.erlang.org/doc/man/sys.html#get_status-1
  end


  def kill_any_follower do
    # TODO
    # :sys.get_state(pid) returns {CurrentStateName, CurrentStateData}
    # see http://www.erlang.org/doc/man/sys.html#get_status-1
  end


  defp get_children_pids do
    Enum.map(Supervisor.which_children(Distributor), fn {_, pid, _, _} -> pid end)
  end

end
