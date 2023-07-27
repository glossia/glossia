defmodule Glossia.ProjectsFixtures do
  @moduledoc """
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

    attrs |> Enum.into(project_fixture_default_attrs()) |> Glossia.Projects.create_project()
  end

  defp project_fixture_default_attrs() do
    %{
      handle: "handle#{Glossia.TestHelpers.unique_integer()}",
      vcs_id: "#{Glossia.TestHelpers.unique_integer()}/#{Glossia.TestHelpers.unique_integer()}",
      git_vcs: :github,
      account_id: 1
    }
  end
end
