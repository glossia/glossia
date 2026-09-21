defmodule Mix.Tasks.Babel.Errors.CreateDsn do
  @moduledoc """
  Provision a Sentry-compatible DSN for an organization and print it.

  Usage:

      mix babel.errors.create_dsn --organization-id 1 [--name default] [--endpoint https://babel.glossia.ai]

  The output is a single line — the DSN — safe to pipe into a secret store.
  """
  use Mix.Task

  alias Babel.Errors
  alias Babel.Repo

  @shortdoc "Provision a Sentry-compatible DSN for an organization"

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [organization_id: :integer, name: :string, endpoint: :string]
      )

    organization_id = Keyword.fetch!(opts, :organization_id)
    name = Keyword.get(opts, :name, "default")
    endpoint = Keyword.get(opts, :endpoint, "https://babel.glossia.ai")

    _organization = Repo.get!(Babel.Organizations.Organization, organization_id)

    key =
      case Enum.find(Errors.list_keys(organization_id), &(&1.name == name)) do
        nil ->
          {:ok, created} = Errors.create_key(organization_id, %{name: name})
          created

        existing ->
          existing
      end

    Mix.shell().info(Errors.Key.dsn(key, endpoint))
  end
end
