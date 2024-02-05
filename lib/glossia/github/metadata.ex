defmodule Glossia.GitHub.Metadata do
  def app_client_id(), do: Glossia.Secrets.get_in([:github, :app, :client_id])
  def app_client_secret(), do: Glossia.Secrets.get_in([:github, :app, :client_secret])
end
