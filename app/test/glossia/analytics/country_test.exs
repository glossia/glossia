defmodule Glossia.Analytics.CountryTest do
  use ExUnit.Case, async: true

  alias Glossia.Analytics.Country

  test "resolves country names and codes to ISO alpha-2 codes" do
    assert Country.code("United States") == "US"
    assert Country.code(" germany ") == "DE"
    assert Country.code("es") == "ES"
    assert Country.code("Czech Republic") == "CZ"
    assert Country.code("Turkey") == "TR"
    assert Country.code("Réunion") == "RE"
    assert Country.code("Åland Islands") == "AX"
  end

  test "covers every ISO territory, including those outside the proficiency dataset" do
    countries =
      JSON.decode!(File.read!(Application.app_dir(:glossia, "priv/analytics-country-names.json")))

    assert map_size(countries) == 249

    for {code, name} <- countries do
      assert Country.code(code) == code
      assert Country.code(name) == code
    end
  end

  test "does not invent a country for invalid data" do
    for value <- [nil, "", "XX", "EU", "Atlantis", %{}, 42] do
      assert Country.code(value) == nil
    end
  end
end
