defmodule Glossia.VersionControl do
  @moduledoc """
  It provides a standard interface for interacting with version control platforms.
  """
  use Boundary, deps: [], exports: []

  # Public / Webhooks

  @spec get_webhook_processor(
          event :: String.t(),
          payload :: map(),
          vcs :: Glossia.VersionControl.Platform.t()
        ) :: nil | {module(), atom(), list()}
  def get_webhook_processor(event, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VersionControl.GitHub.get_webhook_processor(event, payload)
    end
  end

  @spec is_webhook_payload_valid?(
          req_headers :: Keyword.t(),
          payload :: map(),
          vcs :: Glossia.VersionControl.Platform.t()
        ) :: boolean()
  def is_webhook_payload_valid?(req_headers, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VersionControl.GitHub.is_webhook_payload_valid?(req_headers, payload)
    end
  end

  @spec generate_token_for_cloning(
          repository_id :: String.t(),
          vcs :: Glossia.VersionControl.Platform.t()
        ) :: String.t()
  def generate_token_for_cloning(repository_id, vcs) do
    case vcs do
      :github ->
        Glossia.VersionControl.GitHub.generate_token_for_cloning(repository_id)
    end
  end

  # Public / APIs

  @type commit_status_state :: :pending | :success
  @spec create_commit_status(%{
          vcs_id: String.t(),
          vcs_platform: Glossia.VersionControl.Platform.t(),
          state: commit_status_state(),
          target_url: String.t() | nil,
          description: String.t() | nil,
          context: String.t() | nil
        }) :: :ok | {:error, map(), any()}

  def create_commit_status(%{platform: platform} = attrs) do
    case platform do
      "github" ->
        attrs |> Glossia.VersionControl.GitHub.create_commit_status()
    end
  end
end