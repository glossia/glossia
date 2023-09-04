defmodule Glossia.Foundation.Localizations.Core.Utilities.LocalizationRequestParserTest do
  use Glossia.DataCase
  import Glossia.Foundation.Localizations.Core.Workers.LocalizationRequestParser

  describe "parse_localization_request" do
    test "it detects and returns new languages" do
      # Given
      request = %{
        id: "#{Glossia.TestHelpers.unique_integer()}",
        modules: [
          %{
            id: "priv/gettext/{language}/LC_MESSAGES/default.po",
            format: "portable-object",
            localizables: %{
              source: %{
                id: "priv/gettext/en/LC_MESSAGES/default.po",
                checksum: %{
                  cache_id: "priv/gettext/en/LC_MESSAGES/.glossia.default.po.json",
                  content: %{
                    algorithm: "sha256",
                    value: "0d3a96f7401e40e718b308ac09978da74edb3f6ef79f7172d107a8577d8aa0ac"
                  }
                },
                context: %{
                  description:
                    "It represents the structured content of Glossia, an AI-based localization platform. The content is presented in a web app and site.",
                  language: "en"
                }
              },
              target: [
                %{
                  id: "priv/gettext/es/LC_MESSAGES/default.po",
                  checksum: %{
                    cache_id: "priv/gettext/es/LC_MESSAGES/.glossia.default.po.json",
                    content: %{
                      algorithm: "sha256",
                      value: "b65e9fa1d9f71a5bb69d204d3c98897d1627fe41c9acb8cb2dde42fd1893b591"
                    }
                  },
                  context: %{
                    language: "es"
                  }
                }
              ]
            }
          }
        ]
      }

      # When
      [got] = parse_localization_request(request)

      # Then
      assert got[:id] == "priv/gettext/{language}/LC_MESSAGES/default.po"
      assert got[:format] == "portable-object"

      assert got[:source] == %{
               id: "priv/gettext/en/LC_MESSAGES/default.po",
               context: %{
                 description:
                   "It represents the structured content of Glossia, an AI-based localization platform. The content is presented in a web app and site.",
                 language: "en"
               },
               checksum_cache_id: "priv/gettext/en/LC_MESSAGES/.glossia.default.po.json"
             }

      assert got[:target] == [
               new_target_localizable: %{
                 id: "priv/gettext/es/LC_MESSAGES/default.po",
                 context: %{language: "es"},
                 checksum_cache_id: "priv/gettext/es/LC_MESSAGES/.glossia.default.po.json"
               }
             ]
    end
  end
end
