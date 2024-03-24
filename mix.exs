defmodule Glossia.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :glossia,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: [:prod] |> Enum.member?(Mix.env()),
      aliases: aliases(),
      deps: deps(),
      test_coverage: [ignore_modules: [~r/\.TypeEnsurer$/]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Glossia.Application, []},
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
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.18"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:oban, "== 2.17.6"},
      {:dotenvy, "~> 0.8.0"},
      {:ueberauth, "~> 0.10.5"},
      {:ueberauth_github, "~> 0.8"},
      {:tentacat, "~> 2.2"},
      {:nimble_publisher, "~> 1.1.0"},
      {:makeup_elixir, "~> 0.16.0"},
      {:makeup_erlang, "~> 0.1.0"},
      {:timex, "~> 3.0"},
      {:joken, "~> 2.6.0"},
      {:remote_ip, "1.1.0"},
      {:ex_json_schema, "~> 0.10.0"},
      {:goth, "~> 1.4.1"},
      {:google_api_cloud_build, "~> 0.50"},
      {:google_api_storage, "~> 0.37.0"},
      {:rambo, "~> 0.3.4"},
      {:open_api_spex, "~> 3.18.0"},
      {:plug, "~> 1.14"},
      {:policy_wonk, "~> 1.0.0"},
      {:req, "~> 0.4.0"},
      {:useful, "~> 1.14.0"},
      {:typed_struct, "~> 0.3.0"},
      {:modulex, "~> 0.7.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:ecto_erd, "~> 0.5", only: :dev},
      {:hammox, "~> 0.7", only: :test},
      {:nestru, "~> 0.3.3"},
      {:uniq, "~> 0.6.1"},
      {:castore, "~> 1.0"},
      {:stripity_stripe, "~> 3.1.0"},
      {:posthog, "~> 0.1"},
      {:appsignal, "~> 2.0"},
      {:appsignal_phoenix, "~> 2.0"},
      {:redirect, "~> 0.4.0"},
      {:encrypted_secrets, "~> 0.3.0"},
      {:bandit, "~> 1.0"},
      {:flame, "~> 0.1.7"},
      {:exvcr, "~> 0.15", only: :test}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": [
        "esbuild default"
      ],
      "assets.deploy": [
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
