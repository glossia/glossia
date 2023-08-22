defmodule Glossia.Localizations.API.Schemas.LocalizationRequest do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias Glossia.Localizations.API.Schemas.SourceLocalizableContent
  alias Glossia.Localizations.API.Schemas.TargetLocalizableContent

  OpenApiSpex.schema(%{
    title: "A localization request",
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
                source: SourceLocalizableContent,
                target: %Schema{
                  type: :array,
                  description: "The target localizable content of the module.",
                  items: TargetLocalizableContent
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
          "format" => "portable-object-template",
          "id" => "priv/gettext/{language}/LC_MESSAGES/default.po",
          "localizables" => %{
            "source" => %{
              "checksum" => %{
                "cache_id" => "priv/gettext/en/LC_MESSAGES/.glossia.default.po.json",
                "context" => %{
                  "current" => %{
                    "algorithm" => "sha256",
                    "value" => "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                  }
                },
                "content" => %{
                  "current" => %{
                    "algorithm" => "sha256",
                    "value" => "0c9dbab264861da7904ff1e5a2c2684782633e6bd8a24ef137f5091fb65dba75"
                  }
                }
              },
              "context" => %{
                "description" => "This is a test content",
                "language" => "en"
              },
              "id" => "priv/gettext/en/LC_MESSAGES/default.po"
            },
            "target" => [
              %{
                "checksum" => %{
                  "cache_id" => "priv/gettext/es/LC_MESSAGES/.glossia.default.po.json",
                  "context" => %{
                    "current" => %{
                      "algorithm" => "sha256",
                      "value" =>
                        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852bccc"
                    }
                  },
                  "content" => %{
                    "current" => %{
                      "algorithm" => "sha256",
                      "value" =>
                        "0c9dbab264861da7904ff1e5a2c2684782633e6bd8a24ef137f5091fb65dbaaa"
                    }
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
