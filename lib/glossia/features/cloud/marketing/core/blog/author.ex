defmodule Glossia.Features.Cloud.Marketing.Core.Blog.Author do
  @moduledoc """
  A struct that represents a blog author.
  """

  use TypedStruct
  use Domo

  typedstruct(enforce: true) do
    field :id, atom()
    field :name, String.t()
    field :twitter_handle, String.t()
    field :github_handle, String.t()
    field :linkedin_url, String.t()
  end
end
