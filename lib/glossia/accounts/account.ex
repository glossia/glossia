defmodule Glossia.Accounts.Account do
  @moduledoc """
  A module that represents the accounts table
  """
  @type t :: %__MODULE__{
          handle: String.t(),
          projects: [Project.t()] | nil
        }

  use Ecto.Schema
  alias Glossia.Projects.Project

  schema "accounts" do
    field :handle, :string

    has_many(:projects, Project)
    timestamps()
  end
end
