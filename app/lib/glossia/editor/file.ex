defmodule Glossia.Editor.File do
  @moduledoc "A configured repository file, its synchronized base, and a shared editorial draft."
  use Glossia.Schema

  schema "editor_files" do
    belongs_to :project, Glossia.Accounts.Project
    field :path, :string
    field :source_path, :string
    field :locale, :string
    field :format, :string
    field :content, :string
    field :blob_sha, :string
    field :mode, :string, default: "100644"
    field :draft_content, :string
    field :branch, :string
    field :pull_request_url, :string
    field :pull_request_number, :integer
    field :conflict, :boolean, default: false
    field :active, :boolean, default: true
    field :lock_version, :integer, default: 1
    timestamps()
  end
end
