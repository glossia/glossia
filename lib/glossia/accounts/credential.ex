defmodule Glossia.Accounts.Credential do
  use Boundary, deps: []

  alias Glossia.Accounts.{User}
  import Ecto.Changeset

  @type provider :: :github
  @type t :: %__MODULE__{
          provider: provider(),
          provider_id: number(),
          token: String.t(),
          refresh_token: String.t(),
          expires_at: DateTime.t()
        }

  @moduledoc """
  A struct that represents the credentials table.
  """
  use Ecto.Schema

  schema "credentials" do
    field :provider, Ecto.Enum, values: [github: 1]
    field :provider_id, :integer
    field :token, :string, redact: true
    field :refresh_token, :string, redact: true
    field :expires_at, :utc_datetime
    belongs_to :user, User, on_replace: :raise

    timestamps()
  end

  @doc """
  It returns an Ecto.Changeset to create a new credential.
  """
  @spec create_changeset(credential :: __MODULE__.t(), attrs :: map()) ::
          Ecto.Changeset.t()
  def create_changeset(credential, attrs) do
    credential
    |> cast(attrs, [:provider, :provider_id, :token, :refresh_token, :expires_at, :user_id])
    |> validate_required([:provider, :provider_id, :token, :refresh_token, :expires_at, :user_id])
  end

  @type update_user_changeset_attrs :: %{
          user_id: number()
        }
  @spec update_user_changeset(credential :: __MODULE__.t(), attrs :: update_user_changeset_attrs) ::
          Ecto.Changeset.t()
  def update_user_changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
