defmodule Glossia.ContentSourcesFixtures do
  @moduledoc ~S"""
  This module defines test helpers for creating
  entities via the `Glossia.Projects` context.
  """

  def content_source_fixture(attrs \\ %{}) do
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
      |> Enum.into(content_source_fixture_default_attrs())
      |> Glossia.ContentSources.create_content_source()

    project
  end

  defp content_source_fixture_default_attrs() do
    %{
      id_in_content_platform:
        "#{Glossia.TestHelpers.unique_integer()}/#{Glossia.TestHelpers.unique_integer()}",
      content_platform: :github,
      account_id: 1
    }
  end
end
