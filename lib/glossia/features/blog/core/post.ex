defmodule Glossia.Features.Blog.Core.Post do
  @moduledoc """
  A struct that represents a blog post.
  Posts are loaded and serialized at compile-time by `Glossia.Features.Blog.Core`.
  """

  @type t :: %__MODULE__{
          slug: String.t(),
          author_id: String.t(),
          title: String.t(),
          body: String.t(),
          description: String.t(),
          tags: [String.t()],
          date: Date.t()
        }

  @enforce_keys [:slug, :author_id, :title, :body, :description, :tags, :date]
  defstruct [:slug, :author_id, :title, :body, :description, :tags, :date]

  def build(filename, attrs, body) do
    filename_last_component =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()

    [year, month, day] =
      filename_last_component
      |> String.split("-")
      |> Enum.take(3)

    date_string = "#{year}-#{month}-#{day}"
    date = date_string |> Date.from_iso8601!()
    id = filename_last_component |> String.replace(date_string <> "-", "")
    slug = "/blog/posts/" <> year <> "/" <> month <> "/" <> day <> "/" <> id
    struct!(__MODULE__, [slug: slug, date: date, body: body] ++ Map.to_list(attrs))
  end
end
