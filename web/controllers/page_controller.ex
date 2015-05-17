defmodule Raftex.PageController do
  use Phoenix.Controller

  plug :action
  @name :name


  def index(conn, _params) do
    render conn, "index.html"
  end


  def start(conn, params) do
    Distributor.start_link([name: @name])
    text conn, inspect Distributor.start(@name, String.to_integer params["number"])
  end


  def kill_leaders(conn, _params) do
    text conn, inspect Distributor.kill_leaders(@name)
  end


  def kill_any_follower(conn, _params) do
    text conn, inspect Distributor.kill_any_follower(@name)
  end


  def resume(conn, params) do
    text conn, inspect Enum.map(params["numbers"], fn n -> Distributor.resume(@name, String.to_integer(n)) end)
  end


  def info(conn, _params) do
    total = Distributor.get_number_of_nodes(@name)

    nodes = Distributor.get_all_servers(@name) |> Enum.map(
      fn {name, data} ->
        {_, mapName} = data.name
        mapName = String.to_integer(to_string(mapName))
        mapId = mapName - 1
        map = %{
          :name => mapName,
          :id => mapId,
          :state => name,
          :voteCount => if name == :candidate do data.voteCount else nil end
        }
        map
      end
    )

    links = Enum.with_index(nodes) |> Enum.filter(fn {n, _} -> n.state == :follower end) |> Enum.flat_map(
      fn {_, i} ->
        Enum.filter(
          Enum.with_index(nodes),
          fn {m, _} -> m.state == :leader end
        )
        |> Enum.map(fn {_, j} -> %{:source => i, :target => j} end)
      end)
      |> Enum.sort(&(&1.source < &2.source || (&1.source == &2.source && &1.target < &2.target))
    )

    text conn, JSX.encode!(%{:total => total, :nodes => nodes, :links => links})
  end

  def not_found(conn, _params) do
    render conn, "not_found.html"
  end

  def error(conn, _params) do
    render conn, "error.html"
  end
end
