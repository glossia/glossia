defmodule Glossia.Changelog do
  alias Glossia.Changelog.Entry

  use NimblePublisher,
    build: Entry,
    from: Application.app_dir(:glossia, "priv/changelog/**/*.md"),
    as: :entries,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @entries Enum.sort_by(@entries, & &1.date, {:desc, Date})

  def all_entries, do: @entries
end
