defmodule GlossiaWeb.Auth do
  @moduledoc false

  alias Glossia.Accounts, as: Accounts
  alias GlossiaWeb.Support.PathRememberer
  import Phoenix.Controller
  import Plug.Conn
  use GlossiaWeb.Helpers.Shared, :verified_routes
  use GlossiaWeb.Helpers.Shared, :controller

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_glossia_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]
  @authenticated_user_key :authenticated_user
  @authenticated_project_key :authenticated_project

  def remember_me_cookie do
    @remember_me_cookie
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    :ok = Glossia.Analytics.track("log_in", user, %{})

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> assign_authenticated_user(Glossia.Accounts.get_user_by_id(user.id))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      GlossiaWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp signed_in_path(_conn), do: ~p"/"

  @spec user_authenticated?(Plug.Conn.t()) :: boolean()
  def user_authenticated?(conn) do
    conn.assigns[@authenticated_user_key] != nil
  end

  @spec authenticated_subject(Plug.Conn.t()) ::
          Glossia.Accounts.User.t() | Glossia.Projects.Project.t() | nil
  def authenticated_subject(conn) do
    authenticated_user(conn) || authenticated_project(conn)
  end

  @spec authenticated_user(Plug.Conn.t()) ::
          Glossia.Accounts.User.t() | nil
  def authenticated_user(%Plug.Conn{} = conn) do
    conn.assigns[@authenticated_user_key]
  end

  @spec authenticated_user(assigns :: map()) :: Glossia.Accounts.User.t() | nil
  def authenticated_user(assigns) when is_map(assigns) do
    assigns[@authenticated_user_key]
  end

  @spec authenticated_project(Plug.Conn.t()) ::
          Glossia.Projects.Project.t() | nil
  def authenticated_project(conn) do
    conn.assigns[@authenticated_project_key]
  end

  @spec project_authenticated?(Plug.Conn.t()) :: boolean()
  def project_authenticated?(conn) do
    conn.assigns[@authenticated_project_key] != nil
  end

  @spec assign_authenticated_user(Plug.Conn.t(), Glossia.Accounts.User.t()) ::
          Plug.Conn.t()
  def assign_authenticated_user(%Plug.Conn{} = conn, user) do
    Plug.Conn.assign(conn, @authenticated_user_key, user)
  end

  @spec assign_authenticated_user(Phoenix.LiveView.Socket.t(), Glossia.Accounts.User.t()) ::
          Plug.Conn.t()
  def assign_authenticated_user(%Phoenix.LiveView.Socket{} = socket, user) do
    Phoenix.Component.assign(socket, @authenticated_user_key, user)
  end

  def init(:load_authenticated_user = opts), do: opts
  def init(:load_authenticated_project = opts), do: opts
  def init(:load_authenticated_subject = opts), do: opts
  def init(:ensure_authenticated_subject_present = opts), do: opts

  def call(conn, :ensure_authenticated_subject_present) do
    with false <- user_authenticated?(conn),
         false <- project_authenticated?(conn) do
      conn
      |> put_flash(:error, "You must be logged in to access this page.")
      |> redirect(to: ~p"/auth/login")
      |> halt()
    else
      _ ->
        conn
    end
  end

  def call(%Plug.Conn{} = conn, :load_authenticated_subject) do
    conn |> call(:load_authenticated_user) |> call(:load_authenticated_project)
  end

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn, :load_authenticated_project) do
    with {:auth_header, "Bearer" <> " " <> token} <-
           {:auth_header, Plug.Conn.get_req_header(conn, "authorization") |> List.first()},
         {:authenticated_project, %Glossia.Projects.Project{} = project} <-
           {:authenticated_project, Glossia.Projects.get_project_from_token(String.trim(token))} do
      assign(conn, @authenticated_project_key, project)
    else
      {:auth_header, nil} -> assign(conn, @authenticated_project_key, nil)
      {:authenticated_project, nil} -> assign(conn, @authenticated_project_key, nil)
    end
  end

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn, :load_authenticated_user) do
    with {user_token, _} when user_token != nil <- get_conn_token(conn),
         {:user, user} when user != nil <-
           {:user, Glossia.Accounts.get_user_by_session_token(user_token)} do
      conn |> assign(@authenticated_user_key, user)
    else
      _ ->
        conn |> assign(@authenticated_user_key, nil)
    end
  end

  @spec get_conn_token(conn :: Plug.Conn.t()) :: {String.t() | nil, Plug.Conn.t()}
  defp get_conn_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [GlossiaWeb.Auth.remember_me_cookie()])

      if token = conn.cookies[GlossiaWeb.Auth.remember_me_cookie()] do
        {token, GlossiaWeb.Auth.put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end
end
