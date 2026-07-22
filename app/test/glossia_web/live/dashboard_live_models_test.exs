defmodule GlossiaWeb.DashboardLiveModelsTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Accounts.LLMModel
  alias Glossia.TestHelpers

  test "stale sessions sign in before opening model settings", %{conn: conn} do
    path = "/dev/-/settings/models"

    conn =
      conn
      |> init_test_session(%{user_id: Ecto.UUID.generate()})
      |> get(path)

    assert redirected_to(conn) == "/auth/login"
    assert get_session(conn, :return_to) == path
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Sign in to continue."
  end

  test "model configuration keeps the model catalog out of the document tree", %{conn: conn} do
    user = TestHelpers.create_user("model-search@test.com", "model-search")

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/-/settings/models/new")

    {provider_name, [{model_label, model_value} | _]} =
      Enum.find(LLMModel.available_models(), fn {_provider, models} -> models != [] end)

    expected_label = "#{provider_name} - #{model_label}"

    option_count =
      LLMModel.available_models()
      |> Enum.map(fn {_provider, models} -> length(models) end)
      |> Enum.sum()

    html = render(view)

    assert has_element?(
             view,
             "#model-model[phx-hook$='ModelPicker'][phx-update='ignore'][data-option-count='#{option_count}']"
           )

    assert has_element?(view, "#model-model-search[data-part='search-input']")

    assert html =~ expected_label
    assert byte_size(html) < 1_000_000
    assert length(Regex.scan(~r/icon-tabler-schema/, html)) == 1

    view
    |> form("#model-form", %{
      "model" => %{
        "handle" => "translator",
        "model" => "",
        "api_key" => "secret"
      }
    })
    |> render_change()

    view
    |> render_hook("select_model", %{"value" => model_value})

    assert has_element?(view, "#model-handle[value='translator']")
    assert has_element?(view, "#model-api-key[value='secret']")
    assert has_element?(view, "#model-model[data-value='#{model_value}']")
    assert has_element?(view, "#model-save-bar.visible")
  end

  test "invalid model handles show an inline error and cannot be saved", %{conn: conn} do
    user = TestHelpers.create_user("model-validation@test.com", "model-validation")
    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/-/settings/models/new")

    {_provider_name, [{_model_label, model_value} | _]} =
      Enum.find(LLMModel.available_models(), fn {_provider, models} -> models != [] end)

    params = %{
      "model" => %{
        "handle" => "Translator",
        "model" => "",
        "api_key" => "secret"
      }
    }

    view
    |> form("#model-form", params)
    |> render_change()

    view
    |> render_hook("select_model", %{"value" => model_value})

    error =
      "must start with a letter and contain only lowercase letters, numbers, and hyphens"

    assert render(view) =~ error
    assert has_element?(view, ".noora-hint-text[data-variant='destructive']", error)
    refute has_element?(view, "#model-save-bar.visible")

    render_submit(view, "create_model", %{
      "model" => Map.put(params["model"], "model", model_value)
    })

    assert render(view) =~ error
    assert Glossia.LLMModels.get_model_by_handle("Translator", user.account.id) == nil
  end

  test "model settings explain and expose the account default", %{conn: conn} do
    user = TestHelpers.create_user("model-default@test.com", "model-default")

    {:ok, first} =
      Glossia.LLMModels.create_model(user.account, user, %{
        "handle" => "translation-default",
        "model" => "anthropic/claude-sonnet-4-20250514",
        "api_key" => "secret"
      })

    {:ok, second} =
      Glossia.LLMModels.create_model(user.account, user, %{
        "handle" => "long-form",
        "model" => "openai/gpt-5",
        "api_key" => "secret"
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, list_view, _html} =
      live(conn, "/#{user.account.handle}/-/settings/models")

    assert has_element?(list_view, "#llm-model-#{first.id}", "Default")
    assert has_element?(list_view, "#llm-model-#{second.id}")

    {:ok, edit_view, _html} =
      live(conn, "/#{user.account.handle}/-/settings/models/#{second.id}")

    assert has_element?(edit_view, "button[phx-click='set_default_model']", "Make default")

    edit_view
    |> element("button[phx-click='set_default_model']")
    |> render_click()

    assert has_element?(edit_view, ".noora-badge", "Default")
    assert Glossia.LLMModels.default_model(user.account).id == second.id
  end
end
