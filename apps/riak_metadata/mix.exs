defmodule RiakMetadata.MixProject do
  use Mix.Project

  def project do
    [
      app: :riak_metadata,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :riak, :logger_file_backend],
      mod: {RiakMetadata.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:earmark, "~> 1.4", only: :dev},
      {:excoveralls, "~> 0.12", only: :test},
      {:ex_doc, "~> 0.21", only: :dev},
      {:jason, "~> 1.1", override: true},
      {:logger_file_backend, "~> 0.0.11"},
      {:mox, "~> 0.5", only: :test},
      {:nebulex, "~> 1.1"},
      {:riak, "~> 1.1"}
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_),     do: ["lib"]

end
