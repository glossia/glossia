defmodule Glossia.ContentSources do
  @moduledoc """
  It provides a standard interface for interacting with version control platforms.
  """
  use Boundary, deps: [], exports: []

  # Public / Webhooks

  @spec is_webhook_payload_valid?(
          req_headers :: Keyword.t(),
          payload :: map(),
          vcs :: Glossia.ContentSources.Platform.t()
        ) :: boolean()
  def is_webhook_payload_valid?(req_headers, payload, vcs) do
    case vcs do
      :github ->
        Glossia.ContentSources.GitHub.is_webhook_payload_valid?(req_headers, payload)
    end
  end

  @spec generate_token_for_cloning(%{
          vcs_id: String.t(),
          vcs_platform: Glossia.ContentSources.Platform.t()
        }) :: String.t()
  def generate_token_for_cloning(%{vcs_id: vcs_id, vcs_platform: vcs_platform}) do
    case vcs_platform do
      :github ->
        Glossia.ContentSources.GitHub.generate_token_for_cloning(vcs_id)
    end
  end

  # Public / APIs

  @type commit_status_state :: :pending | :success
  @spec create_commit_status(%{
          vcs_id: String.t(),
          vcs_platform: Glossia.ContentSources.Platform.t(),
          state: commit_status_state(),
          target_url: String.t() | nil,
          description: String.t() | nil,
          context: String.t() | nil
        }) :: :ok | {:error, map(), any()}

  def create_commit_status(%{vcs_platform: vcs_platform} = attrs) do
    case vcs_platform do
      "github" ->
        attrs |> Glossia.ContentSources.GitHub.create_commit_status()
    end
  end
end
