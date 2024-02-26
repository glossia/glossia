defmodule GlossiaWeb.LiveViewMountablePlug do
  alias Plug.Conn
  # import Phoenix.Component
  # import Phoenix.LiveView
  use GlossiaWeb.Helpers.Shared, :verified_routes

  def init(:project = opts), do: opts
  def init(:track_page = opts), do: opts

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
    |> Glossia.Authorization.Plug.call(authorize_read_project_opts)
    |> call(:track_page)
  end

  def call(conn, _opts) do
    conn
  end
end
