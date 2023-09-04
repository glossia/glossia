defmodule Glossia.Foundation.Localizations.Core.Utilities.LLMLocalizer do
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

  def localize(content_source, version, content_changes) do
    updates = content_changes |> Enum.map(fn module -> localize_module(content_source, module, version) end)
    {title, description} = title_and_description_from_descriptions(Enum.map(updates, fn update -> update[:description] end))

    %{
      title: title,
      description: description,
      content: Enum.flat_map(updates, fn update -> update[:updates] end)
    }
  end

  def title_and_description_from_descriptions(_descriptions) do
    {"Localization", "Localization is done"}
  end

  def localize_module(content_source, module, version) do
    {:ok, source_content} = ContentSources.get_content(content_source, module[:source][:id], version)

    %{
      description: "Foo",
      updates: Enum.map(module[:target], fn (_type, target) -> [id: target[:id], content: source_content] end)
    }

    # %{
    #   id: "priv/gettext/{language}/LC_MESSAGES/default.po",
    #   format: "portable-object",
    #   source: %{
    #     id: "priv/gettext/en/LC_MESSAGES/default.po",
    #     context: %{
    #       description: "It represents the structured content of Glossia, an AI-based localization platform. The content is presented in a web app and site.",
    #       language: "en"
    #     },
    #     checksum_cache_id: "priv/gettext/en/LC_MESSAGES/.glossia.default.po.json"
    #   },
    #   target: [
    #     new_target_localizable: %{
    #       id: "priv/gettext/es/LC_MESSAGES/default.po",
    #       context: %{language: "es"},
    #       checksum_cache_id: "priv/gettext/es/LC_MESSAGES/.glossia.default.po.json"
    #     }
    #   ]
    # }

    # {id: "README.md", content: "My new content"}
  end
end
