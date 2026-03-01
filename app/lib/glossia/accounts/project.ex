defmodule Glossia.Accounts.Project do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:handle, :name],
    sortable: [:handle, :name, :inserted_at],
    default_order: %{order_by: [:handle], order_directions: [:asc]}
  }

  schema "projects" do
    field :handle, :string
    field :name, :string
    field :github_repo_id, :integer
    field :github_repo_full_name, :string
    field :github_repo_default_branch, :string
    field :setup_status, :string
    field :setup_error, :string
    field :setup_sandbox_id, :string
    field :setup_target_languages, {:array, :string}, default: []
    field :description, :string
    field :url, :string
    field :avatar_url, :string

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :github_installation, Glossia.Accounts.GithubInstallation

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :handle,
      :name,
      :github_repo_id,
      :github_repo_full_name,
      :github_repo_default_branch,
      :setup_status,
      :setup_error,
      :setup_target_languages
    ])
    |> validate_required([:handle, :name])
    |> validate_format(:handle, ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 39)
    |> validate_inclusion(:setup_status, ~w(pending running completed failed),
      message: "is invalid"
    )
    |> unique_constraint([:account_id, :handle])
    |> unique_constraint(:github_repo_id)
  end

  def settings_changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :url, :avatar_url])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_url(:url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: scheme} when scheme in ["http", "https"] -> []
        _ -> [{field, "must be a valid URL starting with http:// or https://"}]
      end
    end)
  end
end
