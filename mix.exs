# mix.exs
defmodule Framework.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "ERP for Printable Services"
  @build_date DateTime.utc_now()

  def project do
    [
      app: :framework,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      # Include "lib" for integration tests
      test_paths: ["test", "lib"],
      aliases: aliases(),
      deps: deps(),
      description: @description,
      releases: releases(),
      build_date: @build_date,
      build_hash: __MODULE__.get_hash()
    ]
  end

  def get_hash do
    {hash, _} = System.cmd("git", ["rev-parse", "--short=8", "HEAD"])
    String.trim(hash)
  catch
    _x -> ""
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Framework.Application, []},
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
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:cinder, "~> 0.5"},
      {:gen_smtp, "~> 1.0"},
      {:oban, "~> 2.0"},
      {:ash_oban, "~> 0.4"},
      {:bcrypt_elixir, "~> 3.0"},
      {:ash_authentication, "~> 4.0"},
      {:ash_authentication_phoenix, "~> 2.0"},
      {:ash_graphql, "~> 1.0"},
      {:ash_json_api, "~> 1.0"},
      {:ash_money, "~> 0.1"},
      {:picosat_elixir, "~> 0.2"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_postgres, "~> 2.5"},
      {:ash, "~> 3.0"},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:ex_money_sql, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:waffle, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_image_info, "~> 1.0.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:tz, "~> 0.28"},
      {:nimble_csv, "~> 1.2"},
      {:icalendar, "~> 1.1"},
      {:imprintor, "~> 0.5"},
      {:open_api_spex, "~> 3.16"},
      {:req, "~> 0.5", only: [:dev, :test]},
      {:sentry, "~> 12.0.1"},
      {:haikunator, github: "data-twister/haikunator"},
      {:faker, "~> 0.18.0"},
      {:cors_plug, "~> 3.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind framework", "esbuild framework"],
      "assets.deploy": [
        "tailwind framework --minify",
        "esbuild framework --minify",
        "phx.digest"
      ],
      "phx.routes": ["phx.routes", "ash_authentication.phoenix.routes"]
    ]
  end

  defp releases do
    [
      craftplan: [
        steps: [:assemble, :tar]
      ]
    ]
  end
end
