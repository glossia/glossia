ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Glossia.Repo, :manual)

# Define mocks
Mox.defmock(Glossia.AI.TranslatorMock, for: Glossia.AI.TranslatorBehaviour)
