defmodule Glossia.NativeThemes do
  @moduledoc """
  Public, instance-wide appearance metadata compiled from the canonical CSS tokens.

  Only unconditional `:root` declarations are read. Theme overrides on web elements
  do not change the native catalog. No filesystem access or user data is involved
  when serving the catalog; changing its content requires recompiling the app.
  """

  @external_resource Path.expand("../../priv/static/assets/styles.css", __DIR__)

  tokens =
    ~r/:root\s*\{([^}]+)\}/s
    |> Regex.scan(File.read!(@external_resource), capture: :all_but_first)
    |> Enum.flat_map(fn [block] ->
      Regex.scan(~r/(--[a-z0-9-]+):\s*([^;]+);/, block, capture: :all_but_first)
    end)
    |> Map.new(fn [name, value] -> {name, String.trim(value)} end)

  resolve = fn resolve, token ->
    value = Map.fetch!(tokens, token)

    case Regex.run(~r/\Avar\((--[a-z0-9-]+)\)\z/, value) do
      [_, reference] -> resolve.(resolve, reference)
      nil -> value
    end
  end

  palettes =
    for {mode, mapping} <- [
          {"light",
           %{
             "background" => "--color-bg",
             "surface" => "--color-surface",
             "subtle" => "--color-bg-subtle",
             "text" => "--color-text",
             "secondary_text" => "--color-text-muted",
             "border" => "--color-border",
             "accent" => "--color-primary",
             "on_accent" => "--color-text-on-accent",
             "tint" => "--color-primary"
           }},
          {"dark",
           %{
             "background" => "--color-native-dark-bg",
             "surface" => "--color-native-dark-surface",
             "subtle" => "--color-native-dark-subtle",
             "text" => "--color-native-dark-text",
             "secondary_text" => "--color-native-dark-text-secondary",
             "border" => "--color-native-dark-border",
             "accent" => "--color-native-dark-accent",
             "on_accent" => "--color-native-dark-on-accent",
             "tint" => "--color-native-dark-tint"
           }}
        ],
        into: %{} do
      palette =
        Map.new(mapping, fn {key, token} ->
          value = resolve.(resolve, token)
          true = Regex.match?(~r/\A#[0-9a-fA-F]{6}\z/, value)
          {key, String.upcase(value)}
        end)

      {mode, palette}
    end

  {button_radius, "px"} = Integer.parse(resolve.(resolve, "--radius-default"))
  {card_radius, "px"} = Integer.parse(resolve.(resolve, "--radius-large"))

  catalog = %{
    "schema_version" => 1,
    "default_theme_id" => "glossia",
    "themes" => [
      Map.merge(palettes, %{
        "id" => "glossia",
        "name" => "Glossia",
        "description" => "Glossia's warm cream and violet appearance.",
        "typography" => "standard",
        "button_radius" => button_radius,
        "card_radius" => card_radius
      })
    ]
  }

  revision =
    :crypto.hash(:sha256, :erlang.term_to_binary(catalog, [:deterministic]))
    |> Base.encode16(case: :lower)

  @catalog Map.put(catalog, "revision", revision)

  def catalog, do: @catalog
end
