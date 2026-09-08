defmodule GlossiaWeb.OgImageControllerTest do
  use GlossiaWeb.ConnCase, async: false
  use Mimic

  alias Glossia.OgImage
  alias Glossia.OgImage.Cache
  alias Glossia.Storage
  alias GlossiaWeb.DashboardSocial

  setup :set_mimic_global

  setup do
    previous = Application.get_env(:glossia, OgImage)
    Application.put_env(:glossia, OgImage, enabled: true)
    on_exit(fn -> Application.put_env(:glossia, OgImage, previous) end)
    :ok
  end

  test "a stored image is served without a browser and accepts image requests", %{conn: conn} do
    attrs = %{title: "Stored #{System.unique_integer([:positive])}", category: "project"}
    key = "og/images/#{OgImage.hash(attrs)}.jpg"
    expect(Storage, :download, fn ^key -> {:ok, %{body: "stored jpeg"}} end)

    response =
      conn
      |> put_req_header("accept", "image/jpeg")
      |> get(OgImage.project_url("dev", "glossia", attrs))

    assert response(response, 200) == "stored jpeg"
    assert get_resp_header(response, "content-type") == ["image/jpeg"]
    assert get_resp_header(response, "cache-control") == ["public, max-age=86400, immutable"]
  end

  test "forged and mismatched hashes cannot reach storage", %{conn: conn} do
    reject(Storage, :download, 1)
    attrs = %{title: "valid"}
    token = OgImage.sign_attrs(attrs)
    assert conn |> get(~p"/og/app/dev/wrong.jpg?#{[d: token]}") |> response(404)
    assert conn |> get(~p"/og/app/dev/missing.jpg") |> response(404)
  end

  test "storage outages never start rendering and remain uncacheable", %{conn: conn} do
    attrs = %{title: "Unavailable #{System.unique_integer([:positive])}"}
    expect(Storage, :download, fn _ -> {:error, :timeout} end)
    result = get(conn, OgImage.account_url("dev", attrs))
    assert response(result, 503)
    assert get_resp_header(result, "cache-control") == ["no-store"]
    assert get_resp_header(result, "retry-after") == ["60"]
  end

  test "yesterday's missing images cannot start a render" do
    name = :"test_cache_#{System.unique_integer([:positive])}"
    start_supervised!({Cache, name: name})
    expect(Storage, :download, fn _ -> {:error, {:http_error, 404, %{}}} end)

    assert {:error, :expired} =
             OgImage.fetch_or_generate("missing", %{}, Date.add(Date.utc_today(), -1), name)
  end

  test "a first hit renders, uploads, and reuses the stored result" do
    name = :"test_cache_#{System.unique_integer([:positive])}"
    start_supervised!({Cache, name: name})
    key = "og/images/first-hit.jpg"
    expect(Storage, :download, 2, fn ^key -> {:error, {:http_error, 404, %{}}} end)
    expect(GlossiaWeb.OgImageHTML, :document, fn %{title: "New project"}, nil -> "template" end)

    expect(Carta, :render, fn Glossia.OgImage.BrowserPool, "template", opts ->
      assert opts == [width: 1200, height: 630, quality: 90]
      {:ok, "new jpeg"}
    end)

    expect(Storage, :upload, fn ^key, "new jpeg", [content_type: "image/jpeg"] -> {:ok, %{}} end)

    assert {:ok, "new jpeg"} =
             OgImage.fetch_or_generate(key, %{title: "New project"}, Date.utc_today(), name)

    assert {:ok, "new jpeg"} =
             OgImage.fetch_or_generate(key, %{title: "New project"}, Date.utc_today(), name)
  end

  test "failed uploads are not served or cached and a later request retries" do
    name = :"test_cache_#{System.unique_integer([:positive])}"
    start_supervised!({Cache, name: name})
    key = "og/images/upload-failure.jpg"
    expect(Storage, :download, 4, fn ^key -> {:error, {:http_error, 404, %{}}} end)
    stub(GlossiaWeb.OgImageHTML, :document, fn _, _ -> "template" end)
    expect(Carta, :render, 2, fn _, _, _ -> {:ok, "jpeg"} end)
    expect(Storage, :upload, fn ^key, "jpeg", _ -> {:error, :unavailable} end)
    expect(Storage, :upload, fn ^key, "jpeg", _ -> {:ok, %{}} end)

    assert {:error, :unavailable} = OgImage.fetch_or_generate(key, %{}, Date.utc_today(), name)
    assert {:ok, "jpeg"} = OgImage.fetch_or_generate(key, %{}, Date.utc_today(), name)
  end

  test "every project section includes its logo and private accounts receive generic content" do
    account = %{handle: "dev", visibility: "public"}

    project = %{
      handle: "glossia",
      name: "Glossia",
      avatar_url: "avatars/dev/projects/glossia.png",
      updated_at: DateTime.utc_now()
    }

    for action <- [
          :project,
          :project_translations,
          :project_session,
          :project_settings,
          :project_analytics,
          :project_analytics_settings
        ] do
      url = DashboardSocial.image_url(account, project, action)
      token = url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query() |> Map.fetch!("d")
      assert {:ok, %{attrs: attrs}} = OgImage.verify_attrs(token)
      assert attrs.project_avatar == project.avatar_url
      assert attrs.title == "Glossia"
    end

    url = DashboardSocial.image_url(%{account | visibility: "private"}, project, :project)
    token = url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query() |> Map.fetch!("d")
    assert {:ok, %{attrs: attrs}} = OgImage.verify_attrs(token)
    refute Map.has_key?(attrs, :project_avatar)
    refute inspect(attrs) =~ "dev"
  end
end
