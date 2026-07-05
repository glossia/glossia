defmodule Glossia.Sandbox do
  @moduledoc """
  Runtime adapter facade for ephemeral sandbox environments.
  """

  @type sandbox_id :: String.t()

  @callback create(map()) :: {:ok, sandbox_id()} | {:error, term()}
  @callback execute(sandbox_id(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  @callback delete(sandbox_id()) :: :ok | {:error, term()}
  @callback download_file(sandbox_id(), String.t()) :: {:ok, binary()} | {:error, term()}
  @callback upload_file(sandbox_id(), String.t(), binary()) :: :ok | {:error, term()}
  @callback delete_file(sandbox_id(), String.t()) :: :ok | {:error, term()}
  @callback repo_path(sandbox_id()) :: {:ok, String.t()} | {:error, term()}
  @callback start_agent_session(sandbox_id(), pid(), keyword()) :: {:ok, pid()} | {:error, term()}

  def adapter do
    :glossia
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:adapter, Glossia.Sandbox.ClusterAdapter)
  end

  def start_agent_session(adapter, sandbox_id, caller, opts) do
    adapter.start_agent_session(sandbox_id, caller, opts)
  end

  def configured(key, default) do
    :glossia
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
