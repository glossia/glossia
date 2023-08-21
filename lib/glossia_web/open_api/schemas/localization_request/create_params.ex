defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.CreateParams do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequestLocalizableContent

  OpenApiSpex.schema(%{
    title: "Localization request create params",
    description: "The parameters used to create a new localization request.",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        description:
          "A string that uniquely identifies the localization request in time. For example, for content hosted in Git repositories, that's the commit SHA."
      },
      modules: %Schema{
        type: :array,
        description: "Modules of localizable content to be localized.",
        items: %Schema{
          type: :object,
          description: "A module of localizable content to be localized.",
          properties: %{
            format: %Schema{type: :string, description: "The format of the module files."},
            id: %Schema{
              type: :string,
              description: "An identifier that uniquely identifies the module int he project."
            },
            localizables: %Schema{
              type: :object,
              description: "The localizable content of the module.",
              properties: %{
                source: LocalizationRequestLocalizableContent,
                target: %Schema{
                  type: :array,
                  description: "The target localizable content of the module.",
                  items: LocalizationRequestLocalizableContent
                }
              },
              required: [:source, :target]
            }
          },
          required: [:format, :id, :localizables]
        }
      }
    },
    required: [:id, :modules],
    example: %{
      "id" => 123,
      "modules" => [
        %{
          "description" => "This is a test content",
          "format" => "portable-object-template",
          "id" => "priv/gettext/{language}/LC_MESSAGES/default.po",
          "localizables" => %{
            "source" => %{
              "checksum" => %{
                "cached" => %{
                  "id" => "priv/gettext/en/LC_MESSAGES/.glossia.default.po.json"
                },
                "current" => %{
                  "algorithm" => "sha256",
                  "value" => "1d4bd15c1549dd6adfde21daf5831eb94e2fcc2f224324f976b69a1737bdeca7"
                }
              },
              "context" => %{
                "language" => "en"
              },
              "id" => "priv/gettext/en/LC_MESSAGES/default.po"
            },
            "target" => [
              %{
                "checksum" => %{
                  "cached" => %{
                    "id" => "priv/gettext/es/LC_MESSAGES/.glossia.default.po.json"
                  },
                  "current" => %{
                    "algorithm" => "sha256",
                    "value" => "f80530784135f6416d99fab5df43492f8977621658bf75c02a92fc44c8dc0b5b"
                  }
                },
                "context" => %{
                  "language" => "es"
                },
                "id" => "priv/gettext/es/LC_MESSAGES/default.po"
              }
            ]
          }
        }
      ]
    }
  })
end
