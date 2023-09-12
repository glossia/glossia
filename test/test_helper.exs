ExUnit.start()

# Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)

Ecto.Adapters.SQL.Sandbox.mode(Glossia.Foundation.Database.Core.Repo, :manual)
