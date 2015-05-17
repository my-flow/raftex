defmodule Raftex.Mixfile do
  use Mix.Project

  def project do
    [app: :raftex,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     deps: deps,
     test_coverage: [tool: ExCoveralls]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: {Raftex, []},
      applications: [:phoenix, :cowboy, :logger]
    ]
  end

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [
     {:exactor, "~> 2.0.0"},
     {:phoenix, github: "phoenixframework/phoenix", tag: "v0.6.1"},
     {:cowboy, "~> 1.0"},
     {:exjsx, "~> 3.0"},
     {:excoveralls, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
