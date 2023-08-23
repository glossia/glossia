defmodule Glossia.Foundation.ContentSources.Platform do
  # Types

  @type t :: :github

  @doc """
  Given the request headers and the payload it validates the payload signature.
  """
  @callback is_webhook_payload_valid?(req_headers :: Keyword.t(), payload :: map()) :: boolean()

  # Callbacks / APIs

  @doc """
  Returns the content of a file in a repository.

  ## Examples

    iex > Glossia.Foundation.ContentSources.Platform.get_file_content("glossia.jsonc", "glossia/glossia")
    {:ok, "..."}
  """
  @callback get_file_content(
              path :: String.t(),
              repository_id :: String.t()
            ) :: {:ok, String.t()} | {:error, map(), any()}

  @callback create_commit_status(
              attrs :: %{
                state: String.t(),
                vcs_id: String.t(),
                commit_sha: String.t(),
                target_url: String.t() | nil,
                description: String.t() | nil,
                context: String.t() | nil
              }
            ) :: :ok | {:error, map(), any()}

  @callback generate_token_for_cloning(vcs_id :: String.t()) :: String.t()
end
