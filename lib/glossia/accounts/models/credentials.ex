defmodule Glossia.Accounts.Models.Credentials do
  # Modules
  alias Glossia.Accounts.Models.{User}
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
  use Glossia.DatabaseSchema

  schema "credentials" do
    field :provider, Ecto.Enum, values: [github: 1]
    field :provider_id, :integer
    field :token, :string, redact: true
    field :refresh_token, :string, redact: true
    field :expires_at, :utc_datetime
    field :refresh_token_expires_at, :utc_datetime
    belongs_to :user, User, on_replace: :raise

    timestamps()
  end

  @doc """
  It returns the default changeset for the credentials table.
  """
  @spec changeset(credentials :: any(), attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(credentials, attrs \\ %{}) do
    credentials
    |> cast(attrs, [
      :provider,
      :provider_id,
      :token,
      :refresh_token,
      :refresh_token_expires_at,
      :expires_at,
      :user_id
    ])
    |> validate_required([:provider, :provider_id, :token, :refresh_token, :expires_at, :user_id])
  end
end
