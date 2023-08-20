defmodule Glossia.Docs.Page do
  @moduledoc """
  A struct that represents a documentation page.
  Pages are loaded and serialized at compile-time by `Glossia.Docs`.
  """

  @type t :: %__MODULE__{
          slug: String.t(),
          title: String.t(),
          body: String.t(),
          description: String.t(),
          tags: [String.t()]
        }

  @enforce_keys [:slug, :title, :body, :description, :tags]
  defstruct [:slug, :title, :body, :description, :tags]

  def build(_filename, _attrs, _body) do
    struct!(__MODULE__,
      slug: "slug",
      title: "title",
      body: "body",
      description: "description",
      tags: ["tags"]
    )

    # filename_last_component =
    #   filename
    #   |> Path.rootname()
    #   |> Path.split()
    #   |> List.last()

    # [year, month, day] =
    #   filename_last_component
    #   |> String.split("-")
    #   |> Enum.take(3)

    # date_string = "#{year}-#{month}-#{day}"
    # date = date_string |> Date.from_iso8601!()
    # id = filename_last_component |> String.replace(date_string <> "-", "")
    # slug = "/blog/posts/" <> year <> "/" <> month <> "/" <> day <> "/" <> id
    # struct!(__MODULE__, [slug: slug, date: date, body: body] ++ Map.to_list(attrs))
  end
end
