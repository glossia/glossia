defmodule Glossia.Foundation.Accounts.Web.Helpers.Auth do
  @authenticated_user_key :authenticated_user

  @doc """
  It returns true if there's a user authenticated in the given connection.
  """
  @spec user_authenticated?(Plug.Conn.t()) :: boolean()
  def user_authenticated?(conn) do
    conn.assigns[@authenticated_user_key] != nil
  end

  @doc """
  If there's a user authenticated in the given connection it returns the user, otherwise it returns nil.
  """
  @spec authenticated_user(Plug.Conn.t()) ::
          Glossia.Foundation.Accounts.Core.Models.User.t() | nil
  def authenticated_user(conn) do
    conn.assigns[@authenticated_user_key]
  end

  @doc """
  It assigns the given user to the given connection.
  """
  @spec assign_authenticated_user(Plug.Conn.t(), Glossia.Foundation.Accounts.Core.Models.User.t()) ::
          Plug.Conn.t()
  def assign_authenticated_user(%Plug.Conn{} = conn, user) do
    Plug.Conn.assign(conn, @authenticated_user_key, user)
  end

  def assign_authenticated_user(%Phoenix.LiveView.Socket{} = socket, user) do
    Phoenix.Component.assign(socket, @authenticated_user_key, user)
  end
end
