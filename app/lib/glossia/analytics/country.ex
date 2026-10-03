defmodule Glossia.Analytics.Country do
  @moduledoc """
  ISO 3166-1 alpha-2 codes and English country names from Unicode CLDR.

  The bundled names cover all 249 ISO territories, not just countries with
  an English-proficiency score. Name resolution supports the flattened,
  unauthenticated ipapi.is response without guessing from a visitor's timezone.
  """

  @external_resource Path.expand("../../../priv/analytics-country-names.json", __DIR__)
  @countries @external_resource |> File.read!() |> JSON.decode!()
  @codes_by_name Map.new(@countries, fn {code, name} -> {String.downcase(name), code} end)
  @aliases %{
    "czech republic" => "CZ",
    "turkey" => "TR",
    "russian federation" => "RU",
    "republic of korea" => "KR",
    "korea, republic of" => "KR",
    "iran, islamic republic of" => "IR",
    "viet nam" => "VN",
    "united states of america" => "US"
  }

  def code(value) when is_binary(value) do
    value = String.trim(value)
    code = String.upcase(value)

    if Map.has_key?(@countries, code) do
      code
    else
      name = String.downcase(value)
      Map.get(@codes_by_name, name) || Map.get(@aliases, name)
    end
  end

  def code(_), do: nil
end
