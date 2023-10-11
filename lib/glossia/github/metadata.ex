defmodule Glossia.GitHub.Metadata do
  use Modulex

  defimplementation do
    def app_client_id(), do: Application.fetch_env!(:glossia, :github_app_client_id)
    def app_client_secret(), do: Application.fetch_env!(:glossia, :github_app_client_secret)
  end

  defbehaviour do
    @callback app_client_id() :: String.t()
    @callback app_client_secret() :: String.t()
  end
end
