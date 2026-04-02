defmodule Glossia.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The scope carries the authenticated user so that public interfaces
  (contexts, controllers, LiveViews) receive a consistent representation
  of who is making the call. Extend this struct as the app grows — for
  example, adding `:account` for multi-tenancy or `:super_admin` flags.
  """

  alias Glossia.Accounts.User

  defstruct user: nil

  @type t :: %__MODULE__{user: User.t() | nil}

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user), do: %__MODULE__{user: user}
  def for_user(nil), do: nil
end
