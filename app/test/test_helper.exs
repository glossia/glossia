ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Glossia.Repo, :manual)

Mimic.copy(ExAws)
Mimic.copy(Glossia.Mailer)
Mimic.copy(Glossia.Extensions)
Mimic.copy(Glossia.TestEventHandler)
