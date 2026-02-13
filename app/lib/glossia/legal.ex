defmodule Glossia.Legal do
  alias Glossia.Legal.Version

  use NimblePublisher,
    build: Version,
    from: Application.app_dir(:glossia, "priv/legal/**/*.md"),
    as: :versions,
    earmark_options: %Earmark.Options{code_class_prefix: "language-", breaks: true}

  @versions Enum.sort_by(@versions, & &1.date, {:desc, Date})

  def all_versions, do: @versions

  def versions_for(document) do
    Enum.filter(@versions, &(&1.document == document))
  end

  def latest_version!(document) do
    case versions_for(document) do
      [latest | _] -> latest
      [] -> raise Glossia.Legal.NotFoundError, "no versions found for document=#{document}"
    end
  end

  def get_version!(document, date_string) do
    date = Date.from_iso8601!(date_string)

    Enum.find(@versions, fn v -> v.document == document and v.date == date end) ||
      raise Glossia.Legal.NotFoundError,
            "version not found for document=#{document}, date=#{date_string}"
  end
end

defmodule Glossia.Legal.NotFoundError do
  defexception [:message, plug_status: 404]
end
