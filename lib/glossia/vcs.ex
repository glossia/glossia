defmodule Glossia.VCS do
  @moduledoc """
  It provides a standard interface for interacting with version control system providers
  like GitHub, Gitlab, Bitbucket, etc.
  """
  use Boundary, deps: [], exports: []

  # Public / Webhooks

  @spec get_webhook_processor(
          event :: String.t(),
          payload :: map(),
          vcs :: Glossia.VCS.ProviderBehaviour.t()
        ) :: nil | {module(), atom(), list()}
  def get_webhook_processor(event, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VCS.GitHub.get_webhook_processor(event, payload)
    end
  end

  @spec is_webhook_payload_valid?(
          req_headers :: Keyword.t(),
          payload :: map(),
          vcs :: Glossia.VCS.ProviderBehaviour.t()
        ) :: boolean()
  def is_webhook_payload_valid?(req_headers, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VCS.GitHub.is_webhook_payload_valid?(req_headers, payload)
    end
  end

  @spec generate_token_for_cloning(
          repository_id :: String.t(),
          vcs :: Glossia.VCS.ProviderBehaviour.t()
        ) :: String.t()
  def generate_token_for_cloning(repository_id, vcs) do
    case vcs do
      :github ->
        Glossia.VCS.GitHub.generate_token_for_cloning(repository_id)
    end
  end

  # Public / APIs

  @type commit_status_state :: :pending | :success
  @spec create_commit_status([
          {:commit_sha, String.t()},
          {:repository_id, String.t()},
          {:vcs, Glossia.VCS.ProviderBehaviour.t()},
          {:state, commit_status_state},
          {:target_url, String.t() | nil},
          {:description, String.t() | nil},
          {:context, String.t() | nil}
        ]) :: :ok | {:error, map(), any()}
  def create_commit_status(attrs) do
    case Keyword.fetch!(attrs, :vcs) do
      :github ->
        Glossia.VCS.GitHub.create_commit_status(attrs)
    end
  end
end
