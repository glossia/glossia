defmodule Babel.Repo do
  use Ecto.Repo,
    otp_app: :babel,
    adapter: Ecto.Adapters.Postgres
end
