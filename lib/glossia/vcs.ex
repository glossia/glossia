defmodule Glossia.VCS do
  @moduledoc """
  It provides a standard interface for interacting with version control system providers
  like Github, Gitlab, Bitbucket, etc.
  """
  use Boundary, deps: [], exports: []

  # Public / Webhooks

  @spec get_webhook_processor(
          event :: String.t(),
          payload :: map(),
          vcs :: Glossia.VCS.Provider.t()
        ) :: nil | {module(), atom(), list()}
  def get_webhook_processor(event, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VCS.Github.get_webhook_processor(event, payload)
    end
  end

  # Public / APIs

  @type commit_status_state :: :pending | :success
  @spec create_commit_status([
          {:commit_sha, String.t()},
          {:repository_id, String.t()},
          {:vcs, Glossia.VCS.Provider.t()},
          {:state, commit_status_state},
          {:target_url, String.t() | nil},
          {:description, String.t() | nil},
          {:context, String.t() | nil}
        ]) :: :ok | {:error, map(), any()}
  def create_commit_status(attrs) do
    case Keyword.fetch!(attrs, :vcs) do
      :github ->
        Glossia.VCS.Github.create_commit_status(attrs)
    end
  end
end
