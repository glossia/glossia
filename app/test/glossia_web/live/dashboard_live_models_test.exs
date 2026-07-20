defmodule GlossiaWeb.DashboardLiveModelsTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Accounts.LLMModel
  alias Glossia.TestHelpers

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
  end
end
