defmodule GlossiaAgent.Application do
  @moduledoc """
  OTP Application for the standalone Burrito binary.

  When running as a library (inside the Phoenix app), this application
  module is not started. When running as a standalone binary, it boots
  Logger and dispatches to the CLI entry point.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: GlossiaAgent.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        if standalone_mode?() do
          Task.start(fn -> GlossiaAgent.CLI.main() end)
        end

        {:ok, pid}

      error ->
        error
    end
  end

  defp standalone_mode? do
    Application.get_env(:glossia_agent, :standalone, false)
  end
end
