defmodule Glossia.Analytics.ProjectSettingsTest do
  use ExUnit.Case, async: true

  alias Glossia.Analytics.ProjectSettings

  describe "normalize_domain/1" do
    test "strips scheme, www., path, port and lowercases" do
      assert ProjectSettings.normalize_domain("https://WWW.Example.com/blog") == "example.com"
      assert ProjectSettings.normalize_domain("http://example.com:8080/x?y=1") == "example.com"
      assert ProjectSettings.normalize_domain("Example.COM") == "example.com"
    end

    test "keeps subdomains other than www." do
      assert ProjectSettings.normalize_domain("https://app.example.com") == "app.example.com"
    end

    test "returns an empty string for nil or blank input" do
      assert ProjectSettings.normalize_domain(nil) == ""
      assert ProjectSettings.normalize_domain("   ") == ""
    end
  end

  describe "changeset/2" do
    test "is valid with a domain and project_id and normalizes the domain" do
      changeset =
        ProjectSettings.changeset(%ProjectSettings{}, %{
          domain: "https://WWW.Example.com/",
          project_id: "11111111-1111-1111-1111-111111111111"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :domain) == "example.com"
    end

    test "requires a domain and a project_id" do
      changeset = ProjectSettings.changeset(%ProjectSettings{}, %{})

      refute changeset.valid?
      assert %{domain: _, project_id: _} = errors_on(changeset)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
