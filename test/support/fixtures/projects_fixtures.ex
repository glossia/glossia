defmodule Glossia.ProjectsFixtures do
  @moduledoc ~S"""
  This module defines test helpers for creating
  entities via the `Glossia.Projects` context.
  """

  def project_fixture(attrs \\ %{}) do
    attrs =
      case attrs[:account_id] do
        nil ->
          organization =
            Glossia.AccountsFixtures.organization_fixture(%{
              handle: "#{Glossia.TestHelpers.unique_integer()}"
            })

          Map.put(attrs, :account_id, organization.account.id)

        _ ->
          attrs
      end

    {:ok, project} =
      attrs
      |> Enum.into(project_fixture_default_attrs())
      |> Glossia.Projects.create_project()

    project
  end

  defp project_fixture_default_attrs() do
    %{
      handle: "handle#{Glossia.TestHelpers.unique_integer()}",
      id_in_content_platform:
        "#{Glossia.TestHelpers.unique_integer()}/#{Glossia.TestHelpers.unique_integer()}",
      content_platform: :github,
      account_id: 1
    }
  end
end
