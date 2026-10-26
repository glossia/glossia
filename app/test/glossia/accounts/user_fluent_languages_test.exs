defmodule Glossia.Accounts.UserFluentLanguagesTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.User
  alias Glossia.TestHelpers

  setup do
    %{user: TestHelpers.create_user("fluent@test.com", "fluent")}
  end

  test "fluency defaults to empty and is independent of UI locale", %{user: user} do
    assert %User{}.fluent_languages == []
    assert Repo.reload!(user).fluent_languages == []

    {:ok, user} = Accounts.update_user_locale(user, "es")
    assert user.fluent_languages == []

    {:ok, user} = Accounts.update_user_fluent_languages(user, ["ar", "he"])
    assert user.locale == "es"
    assert Repo.reload!(user).fluent_languages == ["ar", "he"]

    {:ok, user} = Accounts.update_user_locale(user, "fr")
    assert user.fluent_languages == ["ar", "he"]
  end

  test "canonicalizes and deduplicates while preserving explicit scripts and regions", %{
    user: user
  } do
    languages = ["EN", "en", "pt-br", "ZH-hANT-tw", "SR-lATN-rs", "en-latn-us", "ES-419"]
    expected = ["en", "pt-BR", "zh-Hant-TW", "sr-Latn-RS", "en-Latn-US", "es-419"]

    assert {:ok, user} = Accounts.update_user_fluent_languages(user, languages)
    assert user.fluent_languages == expected
    assert Repo.reload!(user).fluent_languages == expected

    assert {:ok, user} = Accounts.update_user_fluent_languages(user, languages)
    assert user.fluent_languages == expected
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, expected)
    assert user.fluent_languages == expected
  end

  test "accepts non-Latin and RTL languages beyond marketing/UI locales", %{user: user} do
    languages = ~w(ar ar-SA he he-IL fa ur hi bn th ru uk ja ko zh-Hans zh-Hant)
    assert Enum.any?(languages, &(not Glossia.I18n.supported?(&1)))
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, languages)
    assert user.fluent_languages == languages

    targets = Enum.map(Glossia.I18n.common_translation_targets(), &elem(&1, 0))
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, targets)
    assert user.fluent_languages == targets
  end

  test "rejects malformed lists and invented tags without persisting any of the request", %{
    user: user
  } do
    {:ok, user} = Accounts.update_user_fluent_languages(user, ["he"])

    for languages <- [
          nil,
          "en",
          123,
          true,
          %{"0" => "en"},
          [nil],
          [false],
          [123],
          [[]],
          [%{}],
          [""],
          ["  "],
          ["en", "xx"],
          ["zz"],
          ["invented"],
          ["en-Zzzz"],
          ["en-XX"],
          ["en-invented"],
          ["en-x-invented"],
          ["und"],
          ["en_US"],
          [" en"],
          ["English"],
          List.duplicate("en", 51)
        ] do
      assert {:error, changeset} = Accounts.update_user_fluent_languages(user, languages)
      assert errors_on(changeset).fluent_languages != []
      assert Repo.reload!(user).fluent_languages == ["he"]
    end
  end

  test "bounds the input before deduplication and supports repeated clear", %{user: user} do
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, List.duplicate("ar", 50))
    assert user.fluent_languages == ["ar"]
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, [])
    assert user.fluent_languages == []
    assert {:ok, user} = Accounts.update_user_fluent_languages(user, [])
    assert Repo.reload!(user).fluent_languages == []
  end

  test "profile changes support fluency without mass assigning actor fields", %{user: user} do
    outsider = TestHelpers.create_user("other-fluent@test.com", "other-fluent")

    assert {:ok, updated} =
             Accounts.update_user_profile(user, %{
               "name" => "Linguist",
               "fluent_languages" => ["HE", "he", "zh-hant"],
               "id" => outsider.id,
               "account_id" => outsider.account_id,
               "email" => outsider.email,
               "locale" => "fr",
               "super_admin" => true
             })

    assert updated.id == user.id
    assert updated.account_id == user.account_id
    assert updated.email == user.email
    assert updated.locale == user.locale
    refute updated.super_admin
    assert updated.name == "Linguist"
    assert updated.fluent_languages == ["he", "zh-Hant"]
    assert Repo.reload!(outsider).fluent_languages == []

    assert {:ok, updated} = Accounts.update_user_profile(updated, %{bio: "Translator"})
    assert updated.fluent_languages == ["he", "zh-Hant"]

    assert {:error, changeset} =
             Accounts.update_user_profile(updated, %{name: "Not saved", fluent_languages: [""]})

    assert errors_on(changeset).fluent_languages != []
    assert Repo.reload!(user).name == "Linguist"
  end
end
