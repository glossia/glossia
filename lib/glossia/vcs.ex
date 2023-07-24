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

  def create_commit_status(commit_sha, repository_id, vcs, attrs) do
    case vcs do
      :github ->
        Glossia.VCS.Github.create_commit_status(commit_sha, repository_id, attrs)
    end
  end
end
