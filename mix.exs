defmodule Raftex.Mixfile do
  use Mix.Project

  def project do
    [app: :raftex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end


  def application do
    [
      applications: [:logger],
      mod: {RaftEx, []}
    ]
  end


  defp deps do
    [
      {:exactor, "~> 1.0.0"}
    ]
  end
end
