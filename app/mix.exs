defmodule Glossia.MixProject do
  use Mix.Project

  def project do
    [
      app: :glossia,
      version: System.get_env("GLOSSIA_VERSION", "0.1.0"),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # External Enterprise sources otherwise embed checkout-specific absolute paths.
      gettext: [
        write_reference_comments: false,
        write_reference_line_numbers: false,
        sort_by_msgid: :case_sensitive
      ],
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Glossia.Application, []},
      included_applications: [:fun_with_flags],
      # `:lumis` must load before `:mdex` so mdex_native's NIF sees the Lumis
      # feature at boot. Compile-time content publishing calls `MDEx.to_html`
      # which errors with "Lumis is not enabled" otherwise.
      extra_applications: [
        :opentelemetry_exporter,
        :opentelemetry,
        :inets,
        :ssl,
        :logger,
        :runtime_tools,
        :os_mon,
        :lumis,
        :mdex
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"] ++ enterprise_paths("lib")
  defp elixirc_paths(_), do: ["lib"] ++ enterprise_paths("lib")

  defp test_paths, do: ["test"] ++ enterprise_paths("test")

  defp enterprise_paths(directory) do
    case System.get_env("GLOSSIA_EDITION", "core") do
      "core" -> []
      "enterprise" -> [Path.expand("../ee/#{directory}", __DIR__)]
      edition -> raise "Unknown GLOSSIA_EDITION: #{inspect(edition)}; expected core or enterprise"
    end
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Compile-time only: the CLDR locale inventory feeds the reserved handles.
      {:ex_cldr, "~> 2.47", runtime: false},
      {:phoenix, "~> 1.8.3"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.0"},
      {:req, "~> 0.5"},
      {:sentry, "~> 13.2"},
      {:hackney, "~> 1.20"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:opentelemetry, "~> 1.7"},
      {:opentelemetry_exporter, "~> 1.10"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_bandit, "~> 0.3.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_logger_metadata, "~> 0.2.0"},
      {:gettext, "~> 1.0", override: true},
      {:jason, "~> 1.2"},
      {:jose, "~> 1.11"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:assent, "~> 0.3"},
      {:let_me, "~> 1.2"},
      {:boruta, "~> 2.3"},
      {:mdex, "~> 0.13"},
      {:lumis, "~> 0.1"},
      {:uniq, "~> 0.6"},
      {:hammer, "~> 7.0"},
      {:hermes_mcp, "~> 0.9"},
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.11"},
      {:opentelemetry_req, "~> 1.0"},
      {:prom_ex, "~> 1.11"},
      {:tidewave, "~> 0.5", only: :dev},
      {:quokka, "~> 2.12", only: [:dev, :test], runtime: false},
      {:ecto_ch, "~> 0.8"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:flop, "~> 0.26"},
      {:carta, "~> 0.2.0"},
      {:browse_chrome, "~> 0.4.0"},
      {:mimic, "~> 1.10", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:muontrap, "~> 2.0.1", override: true},
      {:req_llm, "~> 1.17"},
      {:yaml_elixir, "~> 2.12"},
      {:toml, "~> 0.7"},
      {:noora, "~> 0.86"},
      {:cloak_ecto, "~> 1.3"},
      {:condukt, "~> 1.12"},
      {:cloak, "~> 1.1"},
      {:fun_with_flags, "~> 1.13", app: false, override: true},
      {:fun_with_flags_ui, "~> 1.1", app: false},
      {:ua_inspector, "~> 3.0"},
      {:cachex, "~> 4.1"},
      # Rustler is required whenever `RUSTLER_PRECOMPILED_FORCE_BUILD_ALL=true`
      # is set — the precompiled artifacts for mdex_native / lumis do not
      # include the Lumis feature, so mix builds them from source and needs
      # rustler to run the build.
      {:rustler, ">= 0.0.0", optional: true}
    ] ++ enterprise_deps()
  end

  defp enterprise_deps do
    if System.get_env("GLOSSIA_EDITION", "core") == "enterprise" do
      [{:flame, "~> 0.5.3"}, {:flame_k8s_backend, "~> 0.6.0"}]
    else
      []
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
      setup: [
        "deps.get",
        "ua_inspector.download --force",
        "ecto.setup",
        "assets.setup",
        "assets.build"
      ],
      "ecto.create": ["db.create"],
      "ecto.migrate": [
        "app.config",
        fn args -> Mix.Tasks.Ecto.Migrate.run(args, &Glossia.Release.run_migrations/4) end
      ],
      "ecto.rollback": [
        "app.config",
        fn args -> Mix.Tasks.Ecto.Rollback.run(args, &Glossia.Release.run_migrations/4) end
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "ua_inspector.download --force",
        "test"
      ],
      "assets.setup": [
        "esbuild.install --if-missing",
        "cmd aube install --prefix assets"
      ],
      "assets.build": ["compile", "esbuild glossia", "esbuild noora", "esbuild glossia_sdk_web"],
      "assets.deploy": [
        "esbuild noora --minify",
        "esbuild glossia --minify",
        "esbuild glossia_sdk_web --minify",
        "phx.digest"
      ],
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --unused",
        "format --check-formatted",
        "test"
      ]
    ]
  end
end
