defmodule Glossia.Foundation.Accounts.Web.Helpers.Auth do
  @doc """
  It returns true if there's a user authenticated in the given connection.
  """
  @spec user_authenticated?(Conn.t()) :: boolean()
  def user_authenticated?(conn) do
    conn.assigns[:authenticated_user] != nil
  end

  @doc """
  If there's a user authenticated in the given connection it returns the user, otherwise it returns nil.
  """
  @spec authenticated_user(Conn.t()) :: Glossia.Foundation.Accounts.Core.Models.User.t() | nil
  def authenticated_user(conn) do
    conn.assigns[:authenticated_user]
  end
end
