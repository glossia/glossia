defmodule Glossia.MixProject do
  use Mix.Project

  def project do
    [
      app: :glossia,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:boundary] ++ Mix.compilers()
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
    dependencies = [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.16"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.23"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:oban, "~> 2.14"},
      {:dotenvy, "~> 0.8.0"},
      {:ueberauth, "~> 0.10.5"},
      {:ueberauth_github, "~> 0.8"},
      {:tentacat, "~> 2.2"},
      {:posthog, "~> 0.1"},
      {:nimble_publisher, "~> 1.0.0"},
      {:makeup_elixir, "~> 0.16.0"},
      {:makeup_erlang, "~> 0.1.0"},
      {:timex, "~> 3.0"},
      {:joken, "~> 2.6.0"},
      {:appsignal, "~> 2.0"},
      {:appsignal_phoenix, "~> 2.0"},
      {:plug_attack, "~> 0.4.2"},
      {:remote_ip, "1.1.0"},
      {:ex_json_schema, "~> 0.10.0"},
      {:boundary, "~> 0.10", runtime: false},
      {:goth, "~> 1.4.1"},
      {:google_api_cloud_build, "~> 0.49"},
      {:google_api_storage, "~> 0.34.0"},
      {:rambo, "~> 0.3.4"},
      {:mox, "~> 1.0.0", only: :test},
      {:stripity_stripe, "~> 2.17.3"},
      {:open_api_spex, "~> 3.18.0"},
      {:plug, "~> 1.14"},
      {:policy_wonk, "~> 1.0.0"},
      {:req, "~> 0.4.0"},
      {:useful, "~> 1.12.1"},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]

    case plan() do
      :cloud -> dependencies ++ [{:oban_web, "~> 2.10.0-rc.2", repo: "oban"}]
      _ -> dependencies
    end
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind app", "tailwind marketing", "esbuild app", "esbuild marketing"],
      "assets.deploy": [
        "tailwind app --minify",
        "tailwind marketing --minify",
        "esbuild app --minify",
        "esbuild marketing --minify",
        "phx.digest"
      ]
    ]
  end

  def plan do
    System.get_env("GLOSSIA_PLAN", "cloud") |> String.to_atom()
  end
end
