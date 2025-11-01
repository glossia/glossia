defmodule GlossiaServer.Repo do
  use Ecto.Repo,
    otp_app: :glossia_server,
    adapter: Ecto.Adapters.Postgres
end
