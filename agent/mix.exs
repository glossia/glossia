defmodule GlossiaAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :glossia_agent,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {GlossiaAgent.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:toml, "~> 0.7"},
      {:yaml_elixir, "~> 2.11"},
      {:jason, "~> 1.2"},
      {:slipstream, "~> 1.2"},
      {:jido, "~> 2.0"}
    ]
  end
end
