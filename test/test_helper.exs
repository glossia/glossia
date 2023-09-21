# Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)

Ecto.Adapters.SQL.Sandbox.mode(Glossia.Foundation.Database.Core.Repo, :manual)

# Mocks
import Hammox

for module <- [
      Glossia.Foundation.Analytics.Core.Posthog
    ] do
  defmock(module.mock_module(), for: module.behaviour_module())
  module.put_application_env_module(module.mock_module())
end

ExUnit.start()
