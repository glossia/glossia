defmodule Glossia.VCS.Provider do
  # Types

  @type t :: :github

  # Callbacks / Webhooks

  @doc """
  Processes a webhook event from a VCS provider.
  """
  @callback get_webhook_processor(event :: String.t(), payload :: map()) :: nil

  # Callbacks / APIs

  @doc """
  Returns the content of a file in a repository.

  ## Examples

    iex > Glossia.VCS.Provider.get_file_content("glossia.jsonc", "glossia/glossia")
    {:ok, "..."}
  """
  @callback get_file_content(
              path :: String.t(),
              repository_id :: String.t()
            ) :: {:ok, String.t()} | {:error, map(), any()}

  @type create_commit_status_attrs ::
          %{
            state: String.t(),
            target_url: String.t() | nil,
            description: String.t() | nil,
            context: String.t() | nil
          }
          | :ok
          | {:error, map(), any()}
  @callback create_commit_status(
              commit_sha :: String.t(),
              repository_id :: String.t(),
              attrs :: create_commit_status_attrs()
            ) :: Tentacat.response()
end
