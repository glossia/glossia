defmodule Glossia.Foundation.Localizations.Core.Utilities.Languages do
  @languages File.read!("priv/languages.json") |> Jason.decode!()
  @external_resource "priv/languages.json"

  def get_language_from_iso_639_1_code(iso_639_1) do
    languages()[iso_639_1]["name"]
  end

  def languages do
    @languages
  end
end
