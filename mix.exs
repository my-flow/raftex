defmodule Raftex.Mixfile do
  use Mix.Project

  def project do
    [app: :raftex,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     deps: deps]
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
     {:exactor, "~> 1.0.0"},
     {:phoenix, git: "https://github.com/phoenixframework/phoenix.git", ref: "ad2eb6e8c3b59881226d4ba0263417914ab050dc"},
     {:cowboy, "~> 1.0"},
     {:jsex, github: "talentdeficit/jsex", tag: "v2.0.0"}
    ]
  end
end
