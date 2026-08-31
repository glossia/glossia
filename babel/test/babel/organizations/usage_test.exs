defmodule Babel.Organizations.UsageTest do
  use ExUnit.Case, async: true

  alias Babel.Organizations.Usage

  test "loads organization usage through the Glossia query client" do
    organization_id = "1d82348e-0175-4abf-aeb8-3f2e8304c7a1"

    query = fn sql, opts ->
      assert sql =~ "WHERE organizations.id = '#{organization_id}'::uuid"
      assert opts == [limit: 1]

      {:ok,
       %{
         "rows" => [
           %{
             "organization_name" => "Example organization",
             "project_count" => "2",
             "translation_count" => "5"
           }
         ]
       }}
    end

    assert {:ok, usage} = Usage.fetch(organization_id, query: query)

    assert usage == %{
             organization_name: "Example organization",
             projects: 2,
             translations: 5
           }
  end

  test "does not query Glossia for an invalid organization identifier" do
    assert {:error, :invalid_organization_id} =
             Usage.fetch("not-an-organization-identifier")
  end
end
