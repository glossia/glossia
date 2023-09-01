defmodule Glossia.Foundation.Accounts.Core.Credentials do
  alias Glossia.Foundation.Accounts.Core.{User}
  import Ecto.Changeset

  @type provider :: :github
  @type t :: %__MODULE__{
          provider: provider(),
          provider_id: integer(),
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
  It returns the default changeset for the credentials table.
  """
  @spec changeset(credentials :: t(), attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(credentials, attrs \\ %{}) do
    credentials
    |> cast(attrs, [:provider, :provider_id, :token, :refresh_token, :expires_at, :user_id])
    |> validate_required([:provider, :provider_id, :token, :refresh_token, :expires_at, :user_id])
  end

  @type update_user_changeset_attrs :: %{
          user_id: integer()
        }
  @spec update_user_changeset(credential :: t(), attrs :: update_user_changeset_attrs) ::
          Ecto.Changeset.t()
  def update_user_changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
