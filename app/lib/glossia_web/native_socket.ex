defmodule GlossiaWeb.NativeSocket.Credential do
  @moduledoc false
  @derive {Inspect, only: []}
  defstruct [:value]
end

defmodule GlossiaWeb.NativeSocket do
  @moduledoc "Bearer-authenticated, websocket-only native subscriptions."
  use Phoenix.Socket

  alias GlossiaWeb.NativeSocket.Credential
  alias GlossiaWeb.Plugs.BearerAuth

  channel "translation:*", GlossiaWeb.TranslationChannel

  @impl true
  def connect(params, socket, %{auth_token: token}) when is_binary(token) do
    with false <- Enum.any?(~w(token access_token auth_token), &Map.has_key?(params, &1)),
         {:ok, user, _scopes, _grant} <- BearerAuth.verify(token) do
      {:ok,
       assign(socket,
         current_user_id: user.id,
         credential: %Credential{value: token}
       )}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket, _info), do: :error

  @impl true
  def id(socket), do: "native:user:#{socket.assigns.current_user_id}"
end
