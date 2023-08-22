defmodule Glossia.ContentSources.ContentSource do
  @type version_t :: :latest | {:version, String.t()}

  @doc """
  It returns the content from a content source.

  ## Parameters
  - `content_id` - The content id. What it refers to depends on the content source. For example, in the case of a Git repository is the path to the file.
  - `version` - The version of the content. It can be `:latest` or a specific version. In the case of content sources like GitHub, it represents the commit SHA when pulling a specific version.
  - `project_id` - The project id. What it refers to depends on the content source. For example, in the case of a Git repository is the repository "owner/repository" identifier.
  """
  @callback get_content(content_id :: String.t(), version :: version_t, project_id :: String.t()) ::
              {:ok, String.t()} | {:error, any()}
end
