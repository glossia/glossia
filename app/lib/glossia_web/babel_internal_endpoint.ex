defmodule GlossiaWeb.BabelInternalEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :glossia

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    body_reader: {GlossiaWeb.BodyReader, :read_body, []}

  plug GlossiaWeb.BabelInternalRouter
end
