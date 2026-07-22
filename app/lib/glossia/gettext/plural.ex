defmodule Glossia.Gettext.Plural do
  @moduledoc """
  Supports language tags with hyphen-separated regions and scripts.
  """

  @behaviour Gettext.Plural

  @impl true
  def nplurals(locale) do
    locale
    |> normalize_locale()
    |> Gettext.Plural.nplurals()
  end

  @impl true
  def plural(locale, count) do
    locale
    |> normalize_locale()
    |> Gettext.Plural.plural(count)
  end

  @impl true
  def plural_forms_header(locale) do
    locale
    |> normalize_locale()
    |> Gettext.Plural.plural_forms_header()
  end

  defp normalize_locale(locale), do: String.replace(locale, "-", "_")
end
