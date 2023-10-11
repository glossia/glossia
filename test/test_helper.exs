# Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)

Ecto.Adapters.SQL.Sandbox.mode(Glossia.Repo, :manual)

# Mocks
import Hammox

for module <- [
      Glossia.Analytics.Posthog
    ] do
  defmock(module.mock_module(), for: module.behaviour_module())
  module.put_application_env_module(module.mock_module())
end

ExUnit.start()
