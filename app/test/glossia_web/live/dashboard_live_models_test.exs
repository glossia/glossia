defmodule GlossiaWeb.DashboardLiveModelsTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Accounts.LLMModel
  alias Glossia.TestHelpers

  test "model configuration uses a searchable Noora dropdown", %{conn: conn} do
    user = TestHelpers.create_user("model-search@test.com", "model-search")

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/-/settings/models/new")

    assert has_element?(
             view,
             "#model-model[phx-hook='NooraDropdown'] #model-model-search[data-part='search-input']"
           )

    assert render(view) =~ ~s(id="model-model-content-portal")
    assert render(view) =~ ~s(data-part="item")

    view
    |> form("#model-form", %{
      "model" => %{"handle" => "translator", "model" => "", "api_key" => "secret"}
    })
    |> render_change()

    {provider_name, [{model_label, model_value} | _]} =
      Enum.find(LLMModel.available_models(), fn {_provider, models} -> models != [] end)

    expected_label = "#{provider_name} - #{model_label}"

    view
    |> render_hook("select_model", %{"value" => model_value})

    assert has_element?(
             view,
             "input[name='model[model]'][value='#{model_value}']"
           )

    assert has_element?(view, "#model-handle[value='translator']")
    assert has_element?(view, "#model-api-key[value='secret']")

    assert render(view) =~
             ~r/id="model-model-label-portal"[^>]*>.*#{Regex.escape(expected_label)}/s
  end
end
