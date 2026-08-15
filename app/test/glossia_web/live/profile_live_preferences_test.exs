defmodule GlossiaWeb.ProfileLivePreferencesTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Accounts
  alias Glossia.TestHelpers

  test "the language a user picks is stored on their account", %{conn: conn} do
    user = TestHelpers.create_user("preferences-language@test.com", "preferenceslanguage")

    {:ok, view, html} =
      conn
      |> init_test_session(%{user_id: user.id})
      |> live(~p"/-/settings/preferences")

    assert html =~ "Español"

    # The payload is the one Noora's select hook actually pushes: it forwards
    # Zag's event object, whose value is a list even for a single selection.
    render_hook(view, "select_locale", %{"value" => ["es"], "items" => [%{"value" => "es"}]})
    render_submit(view, "save_locale", %{})

    assert Accounts.get_user(user.id).locale == "es"
  end

  test "a select payload without a usable value leaves the account alone", %{conn: conn} do
    user = TestHelpers.create_user("preferences-empty@test.com", "preferencesempty")

    {:ok, view, _html} =
      conn
      |> init_test_session(%{user_id: user.id})
      |> live(~p"/-/settings/preferences")

    render_hook(view, "select_locale", %{"value" => []})
    render_submit(view, "save_locale", %{})

    assert Accounts.get_user(user.id).locale == "en"
  end

  test "the account language beats the locale frozen into the live session" do
    # The live session is stamped at the first page load and never refreshed,
    # so a remount after a language change would otherwise render the old one.
    socket =
      %Phoenix.LiveView.Socket{}
      |> Phoenix.Component.assign(:current_user, %Glossia.Accounts.User{locale: "es"})

    {:cont, socket} =
      GlossiaWeb.LocaleHooks.on_mount(:put_locale, %{}, %{"locale" => "en"}, socket)

    assert socket.assigns.locale == "es"
    assert Gettext.get_locale(GlossiaWeb.Gettext) == "es"
  after
    Gettext.put_locale(GlossiaWeb.Gettext, "en")
  end

  test "an anonymous visitor keeps the locale from the live session" do
    socket = Phoenix.Component.assign(%Phoenix.LiveView.Socket{}, :current_user, nil)

    {:cont, socket} =
      GlossiaWeb.LocaleHooks.on_mount(:put_locale, %{}, %{"locale" => "ja"}, socket)

    assert socket.assigns.locale == "ja"
  after
    Gettext.put_locale(GlossiaWeb.Gettext, "en")
  end

  test "the dashboard renders in the language of the account", %{conn: conn} do
    user = TestHelpers.create_user("preferences-rendered@test.com", "preferencesrendered")
    {:ok, user} = Accounts.update_user_locale(user, "es")

    {:ok, _view, html} =
      conn
      |> init_test_session(%{user_id: user.id})
      |> live(~p"/-/settings/preferences")

    # The shell around the page is already translated, which is what proves the
    # LiveView process picked up the account's language.
    assert html =~ "Alternar barra lateral"
  end

  test "signing up adopts the language of the browser", %{conn: _conn} do
    {:ok, user} =
      Accounts.find_or_create_user_from_oauth(
        :github,
        %{
          user: %{
            "sub" => "locale-signup-1",
            "email" => "locale-signup@test.com",
            "name" => "Locale Signup",
            "preferred_username" => "localesignup"
          },
          token: %{"access_token" => "token"}
        },
        locale: "ja"
      )

    assert user.locale == "ja"
  end

  test "an unsupported browser language leaves the account on English", %{conn: _conn} do
    {:ok, user} =
      Accounts.find_or_create_user_from_oauth(
        :github,
        %{
          user: %{
            "sub" => "locale-signup-2",
            "email" => "locale-signup-2@test.com",
            "name" => "Locale Signup Two",
            "preferred_username" => "localesignuptwo"
          },
          token: %{"access_token" => "token"}
        },
        locale: "sv"
      )

    assert is_nil(user.locale)
  end
end
