defmodule GlossiaWeb.Helpers.OpenGraph do
  import Plug.Conn

  @assigns_key :open_graph_metadata

  @spec put_open_graph_metadata(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def put_open_graph_metadata(%Plug.Conn{} = conn, metadata) do
    assign(conn, @assigns_key, metadata)
  end

  @spec put_open_graph_metadata(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
  def put_open_graph_metadata(%Phoenix.LiveView.Socket{} = socket, metadata) do
    Phoenix.Component.assign(socket, @assigns_key, metadata)
  end

  @spec get_open_graph_metadata(map()) :: map()
  def get_open_graph_metadata(assigns) do
    app_metadata = Application.get_env(:glossia, @assigns_key)
    assigns_metadata = Map.get(assigns, @assigns_key, %{})

    assigns_metadata =
      assigns_metadata
      |> Map.update(:title, app_metadata.title, fn value ->
        "#{value} · #{app_metadata.title}"
      end)

    Map.merge(app_metadata, assigns_metadata)
  end
end
