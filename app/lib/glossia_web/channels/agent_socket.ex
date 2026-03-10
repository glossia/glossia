defmodule GlossiaWeb.AgentSocket do
  @moduledoc false

  use Phoenix.Socket

  channel "agent:setup:*", GlossiaWeb.AgentChannel
  channel "agent:translate:*", GlossiaWeb.AgentChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "agent_session", token, max_age: 600) do
      {:ok, project_id} ->
        {:ok, assign(socket, :project_id, project_id)}

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "agent_socket:#{socket.assigns.project_id}"
end
