defmodule Cdmi.MixProject do
  use Mix.Project

  def project do
    [
      app: :cdmi,
      build_path: "../../_build",
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      config_path: "../../config/config.exs",
      deps: deps(),
      deps_path: "../../deps",
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      lockfile: "../../mix.lock",
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: "0.1.0"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Cdmi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cdmioid, git: "https://github.com/building39/cdmioid.git", branch: "master"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:earmark, "~> 1.4", only: :dev},
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_doc, "~> 0.21", only: :dev},
      {:gettext, "~> 0.11"},
      {:hexate, "~> 0.6"},
      {:jason, "~> 1.0"},
      {:logger_file_backend, "~> 0.0"},
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:riak_metadata, in_umbrella: true},
      {:uuid, "~> 1.1"}
    ]
  end
end
