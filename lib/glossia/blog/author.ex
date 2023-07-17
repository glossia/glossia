defmodule Glossia.Blog.Author do
  @moduledoc """
  A struct that represents a blog author.
  Authors are loaded and serialized at compile-time by `Glossia.Blog`.
  """
  use Boundary, deps: [], exports: []

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          github_handle: String.t(),
          twitter_handle: String.t(),
          linkedin_url: String.t()
        }

  @enforce_keys [:id, :name, :twitter_handle, :github_handle, :linkedin_url]
  defstruct [:id, :name, :twitter_handle, :github_handle, :linkedin_url]
end
