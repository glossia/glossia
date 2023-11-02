defmodule GlossiaWeb.LiveViewMountablePlug do
  alias Plug.Conn
  import Phoenix.Component
  import Phoenix.LiveView

  @url_project_key :url_project

  def init(:project = opts), do: opts
  def init(:load_url_project = opts), do: opts
  def init(:track_page = opts), do: opts
  def init(:save_last_visited_project = opts), do: opts

  def call(conn, :save_last_visited_project) do
    save_last_visited_project(conn)
  end

  def call(%{request_path: request_path} = conn, :track_page) do
    case GlossiaWeb.Auth.authenticated_user(conn) do
      nil ->
        conn

      %Glossia.Accounts.User{} = user ->
        Glossia.Analytics.track_page_view(request_path, user)
        conn
    end
  end

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{} = conn, :project) do
    authorize_read_project_opts =
      Glossia.Authorization.Plug.init(
        policy: Glossia.Projects,
        action: :read,
        subject: {GlossiaWeb.Auth, :authenticated_subject},
        params: {GlossiaWeb.LiveViewMountablePlug, :url_project}
      )

    conn
    |> call(:load_url_project)
    |> Glossia.Authorization.Plug.call(authorize_read_project_opts)
    |> call(:save_last_visited_project)
    |> call(:track_page)
  end

  def call(
        %Plug.Conn{params: params} =
          conn,
        :load_url_project
      ) do
    Plug.Conn.assign(conn, @url_project_key, find_project(params))
  end

  def call(conn, :load_url_project), do: conn

  def call(conn, _opts) do
    conn
  end

  def on_mount(:project_live_session, params, %{"user_token" => user_token} = _session, socket) do
    authenticated_user = GlossiaWeb.Auth.get_user_from_token(user_token)
    project = find_project(params)

    if Glossia.Authorization.permit?(Glossia.Projects, :read, authenticated_user, project) do
      socket =
        socket
        |> GlossiaWeb.Auth.assign_authenticated_user(authenticated_user)
        |> assign(@url_project_key, project)
        |> save_last_visited_project()

      {:cont, socket}
    else
      socket = socket |> put_flash(:error, "You are not authorized to view this project")
      {:halt, redirect(socket, to: "/")}
    end
  end

  @spec save_last_visited_project(Conn.t() | Phoenix.LiveView.Socket.t()) ::
          Conn.t() | Phoenix.LiveView.Socket.t()
  defp save_last_visited_project(%{assigns: %{url_project: project}} = conn_or_socket) do
    authenticated_user = GlossiaWeb.Auth.authenticated_user(conn_or_socket.assigns)

    with {:project, %Glossia.Projects.Project{} = project} <- {:project, project},
         {:authorized, true} <-
           {:authorized,
            Glossia.Authorization.permit?(Glossia.Projects, :read, authenticated_user, project)},
         {:last_visited_project_updated, :ok} <-
           {:last_visited_project_updated,
            Glossia.Projects.Repository.update_last_visited_project_for_user(
              authenticated_user,
              project
            )} do
      conn_or_socket
    else
      {:project, nil} -> conn_or_socket
      {:authorized, false} -> conn_or_socket
      {:last_visited_project_updated, :ok} -> conn_or_socket
    end
  end

  defp find_project(%{"owner_handle" => owner_handle, "project_handle" => project_handle}) do
    Glossia.Projects.find_project_by_owner_and_project_handle(owner_handle, project_handle)
  end

  defp find_project(_params) do
    nil
  end

  def url_project(%Conn{} = conn), do: conn.assigns[@url_project_key]
  def url_project(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns[@url_project_key]

  def url_project?(%Conn{} = conn), do: conn.assigns[@url_project_key] != nil

  def url_project?(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns[@url_project_key] != nil
end
