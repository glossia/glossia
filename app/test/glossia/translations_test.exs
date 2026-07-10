defmodule Glossia.TranslationsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Translations
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("translations-ctx@test.com", "translations-ctx")
    %{account: user.account}
  end

  defp payload(overrides) do
    Map.merge(
      %{
        "model" => "translator",
        "format" => "markdown",
        "source_language" => "English",
        "language" => "Spanish",
        "locale" => "es",
        "source_content" => "Hello, world."
      },
      overrides
    )
  end

  describe "translate/2 validation" do
    test "rejects an unsupported format before touching the model", %{account: account} do
      assert {:error, {:invalid_format, "xml"}} =
               Translations.translate(account, payload(%{"format" => "xml"}))
    end

    test "requires the translation locale metadata", %{account: account} do
      assert {:error, {:missing_field, "source_language"}} =
               Translations.translate(account, payload(%{"source_language" => ""}))

      assert {:error, {:missing_field, "language"}} =
               Translations.translate(account, payload(%{"language" => nil}))

      assert {:error, {:missing_field, "locale"}} =
               Translations.translate(account, payload(%{"locale" => "  "}))
    end

    test "requires source content", %{account: account} do
      assert {:error, {:missing_field, "source_content"}} =
               Translations.translate(account, payload(%{"source_content" => nil}))
    end

    test "errors when no credential resolves (no account model, config, or session)", %{
      account: account
    } do
      # In the test env local sessions are disabled and no inference config is set,
      # so an account with no models yields no credential.
      assert {:error, {:model_not_found, _}} =
               Translations.translate(account, payload(%{"model" => "translator"}))
    end
  end
end
