defmodule Glossia.SandboxBench.MixProject do
  use Mix.Project

  def project do
    [app: :sandbox_bench, version: "0.1.0", elixir: "~> 1.15", deps: deps()]
  end

  def application, do: [extra_applications: [:logger, :ssl]]

  defp deps do
    [{:muontrap, "~> 1.6"}, {:jason, "~> 1.4"}, {:req, "~> 0.5"}]
  end
end
