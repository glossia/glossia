defmodule Glossia.Foundation.ContentSources.ContentSource do
  @type version_t :: :latest | {:version, String.t()}

  @doc """
  It returns the content from a content source.

  ## Parameters
  - `module` - An instance of the content source module, which might contain state, for example the session information.
  - `content_id` - The content id. What it refers to depends on the content source. For example, in the case of a Git repository is the path to the file.
  - `version` - The version of the content. It can be `:latest` or a specific version. In the case of content sources like GitHub, it represents the commit SHA when pulling a specific version.
  """
  @callback get_content(content_source :: module(), content_id :: String.t(), version :: version_t) ::
              {:ok, String.t()} | {:error, any()}


  @doc """
  It returns the most recent version. In the case of a Git content source, it returns
  the most recent commit sha in the default branch.

  ## Parameters
  - `module` - An instance of the content source module, which might contain state, for example the session information.

  ## Examples

      iex> Glossia.Foundation.ContentSources.GitHub.get_most_recent_version(github_content_source)
      {:ok, "6c325ef99cb6afa8d0cb87a565dc1f59ab46fb67"}
  """
  @callback get_most_recent_version(content_source :: module()) :: {:ok, String.t()} | {:error, any()}
end
