defmodule GlossiaWeb.NativeThemesControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.NativeThemes

  @palette_keys ~w(background surface subtle text secondary_text border accent on_accent tint)

  test "public catalog has the native contract and can be cached without credentials", %{
    conn: conn
  } do
    response = get(conn, ~p"/api/native/themes")
    catalog = json_response(response, 200)

    assert get_resp_header(response, "cache-control") == ["public, max-age=300"]
    assert get_resp_header(response, "set-cookie") == []

    assert Map.keys(catalog) |> Enum.sort() ==
             Enum.sort(~w(schema_version revision default_theme_id themes))

    assert catalog["schema_version"] == 1
    assert catalog["default_theme_id"] == "glossia"
    assert String.trim(catalog["revision"]) != ""
    assert byte_size(catalog["revision"]) <= 128
    assert [theme] = catalog["themes"]

    assert Map.keys(theme) |> Enum.sort() ==
             Enum.sort(~w(id name description typography button_radius card_radius light dark))

    assert theme["id"] == "glossia"
    assert theme["name"] == "Glossia"
    assert String.trim(theme["description"]) != ""
    assert theme["typography"] == "standard"
    assert theme["button_radius"] == 8
    assert theme["card_radius"] == 12

    assert theme["light"] == %{
             "background" => "#FAF8F5",
             "surface" => "#FFFFFF",
             "subtle" => "#F2EFE9",
             "text" => "#1C1917",
             "secondary_text" => "#5C564E",
             "border" => "#E4E0D9",
             "accent" => "#6D3CC4",
             "on_accent" => "#FFFFFF",
             "tint" => "#6D3CC4"
           }

    assert theme["dark"] == %{
             "background" => "#1C1917",
             "surface" => "#2A2621",
             "subtle" => "#2A2621",
             "text" => "#FAF8F5",
             "secondary_text" => "#D1CDC5",
             "border" => "#3D3833",
             "accent" => "#D0BCFF",
             "on_accent" => "#381E72",
             "tint" => "#D0BCFF"
           }

    for mode <- ~w(light dark), {_, color} <- theme[mode] do
      assert color =~ ~r/\A#[0-9A-F]{6}\z/
    end

    assert conn
           |> put_req_header("authorization", "Bearer invalid")
           |> get(~p"/api/native/themes")
           |> json_response(200) == catalog
  end

  test "catalog follows root semantic tokens, not scoped web overrides" do
    css = File.read!(Path.expand("../../../priv/static/assets/styles.css", __DIR__))

    tokens =
      for [block] <- Regex.scan(~r/:root\s*\{([^}]+)\}/s, css, capture: :all_but_first),
          [name, value] <-
            Regex.scan(~r/(--[a-z0-9-]+):\s*([^;]+);/, block, capture: :all_but_first),
          into: %{},
          do: {name, String.trim(value)}

    [theme] = NativeThemes.catalog()["themes"]

    for {key, token} <- %{
          "background" => "--color-bg",
          "surface" => "--color-surface",
          "subtle" => "--color-bg-subtle",
          "text" => "--color-text",
          "secondary_text" => "--color-text-muted",
          "border" => "--color-border",
          "accent" => "--color-primary",
          "on_accent" => "--color-text-on-accent",
          "tint" => "--color-primary"
        } do
      assert theme["light"][key] == String.upcase(resolve(tokens, token))
    end

    for {key, suffix} <- %{
          "background" => "bg",
          "surface" => "surface",
          "subtle" => "subtle",
          "text" => "text",
          "secondary_text" => "text-secondary",
          "border" => "border",
          "accent" => "accent",
          "on_accent" => "on-accent",
          "tint" => "tint"
        } do
      assert theme["dark"][key] ==
               String.upcase(resolve(tokens, "--color-native-dark-#{suffix}"))
    end

    assert "#{theme["button_radius"]}px" == resolve(tokens, "--radius-default")
    assert "#{theme["card_radius"]}px" == resolve(tokens, "--radius-large")
  end

  test "revision is a deterministic digest of the entire catalog" do
    catalog = NativeThemes.catalog()

    expected =
      :crypto.hash(
        :sha256,
        :erlang.term_to_binary(Map.delete(catalog, "revision"), [:deterministic])
      )
      |> Base.encode16(case: :lower)

    assert catalog["revision"] == expected
    assert NativeThemes.catalog() == catalog
  end

  test "public appearance metadata does not make user or project APIs public", %{conn: conn} do
    assert conn |> get(~p"/api/me") |> json_response(401)

    assert conn
           |> get(~p"/api/native/projects/example/translations")
           |> json_response(401)
  end

  test "OpenAPI publishes public security, cache policy and all required catalog fields", %{
    conn: conn
  } do
    spec = conn |> get(~p"/api/openapi.json") |> json_response(200)
    operation = spec["paths"]["/api/native/themes"]["get"]
    schemas = spec["components"]["schemas"]

    assert operation["security"] == []

    assert operation["responses"]["200"]["headers"]["Cache-Control"]["schema"]["const"] ==
             "public, max-age=300"

    assert operation["responses"]["200"]["content"]["application/json"]["schema"]["$ref"] ==
             "#/components/schemas/NativeThemeCatalog"

    assert Enum.sort(schemas["NativeThemeCatalog"]["required"]) ==
             Enum.sort(~w(schema_version revision default_theme_id themes))

    assert schemas["NativeThemeCatalog"]["properties"]["schema_version"]["const"] == 1
    assert schemas["NativeThemeCatalog"]["properties"]["revision"]["maxLength"] == 128
    assert schemas["NativeThemeCatalog"]["properties"]["default_theme_id"]["const"] == "glossia"

    assert Enum.sort(schemas["NativeTheme"]["required"]) ==
             Enum.sort(~w(id name description typography button_radius card_radius light dark))

    assert Enum.sort(schemas["NativeThemePalette"]["required"]) == Enum.sort(@palette_keys)

    for key <- @palette_keys do
      pattern = schemas["NativeThemePalette"]["properties"][key]["pattern"] |> Regex.compile!()
      assert hd(NativeThemes.catalog()["themes"])["light"][key] =~ pattern
      assert hd(NativeThemes.catalog()["themes"])["dark"][key] =~ pattern
    end
  end

  defp resolve(tokens, token) do
    case Map.fetch!(tokens, token) do
      "var(" <> reference -> resolve(tokens, String.trim_trailing(reference, ")"))
      value -> value
    end
  end
end
