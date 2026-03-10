ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Glossia.Repo, :manual)

Mimic.copy(ExAws)
Mimic.copy(Glossia.Mailer)
Mimic.copy(Glossia.Github.Webhook)
Mimic.copy(Glossia.Sandbox.Docker)
