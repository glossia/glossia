defmodule Glossia.Repo do
  # Modules
  use Boundary
  use Ecto.Repo,
    otp_app: :glossia,
    adapter: Ecto.Adapters.Postgres
end
