defmodule Raftex.PageController do
  use Phoenix.Controller

  plug :action


  def index(conn, _params) do
    render conn, "index"
  end


  def start(conn, _params) do
    text conn, inspect Raftex.run
  end


  def kill_leaders(conn, _params) do
    text conn, inspect Distributor.kill_leaders
  end


  def kill_any_follower(conn, _params) do
    text conn, inspect Distributor.kill_any_follower
  end


  def resume(conn, params) do
    text conn, inspect Enum.map(params["numbers"], fn n -> Distributor.resume String.to_integer n end)
  end


  def info(conn, _params) do
    nodes = Distributor.get_all_servers |> Enum.map(
      fn {name, data} -> 
        %{
          :name => data.name, 
          :id => data.name - 1, 
          :state => name}
      end
    )

    links = Enum.with_index(nodes) |> Enum.flat_map(
      fn {n, i} ->
        Enum.reject(
          Enum.with_index(nodes),
          fn {m, j} -> m == n || j < i end
        )
        |> Enum.map(fn {m, j} -> %{:source => i, :target => j} end)
      end)
      |> Enum.sort(&(&1.source < &2.source || (&1.source == &2.source && &1.target < &2.target))
    )

    text conn, JSEX.encode!(%{:nodes => nodes, :links => links})
  end

  def not_found(conn, _params) do
    render conn, "not_found"
  end

  def error(conn, _params) do
    render conn, "error"
  end
end
