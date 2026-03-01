defmodule Glossia.Kits.KitStar do
  use Glossia.Schema
  import Ecto.Changeset

  schema "kit_stars" do
    belongs_to :kit, Glossia.Kits.Kit
    belongs_to :user, Glossia.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(star, attrs) do
    star
    |> cast(attrs, [])
    |> unique_constraint([:kit_id, :user_id])
  end
end
