defmodule Glossia.GitHub.App do
  def installation_url() do
    app_name = Glossia.Secrets.get_in([:github, :app, :name])
    "https://github.com/apps/#{app_name}/installations/new"
  end

  def bot_handle() do
    Glossia.Secrets.get_in([:github, :app, :bot_handle])
  end
end
