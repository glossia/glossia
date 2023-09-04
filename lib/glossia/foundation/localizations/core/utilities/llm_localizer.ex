defmodule Glossia.Foundation.Localizations.Core.Utilities.LLMLocalizer do
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.LLMs.Core, as: LLMs
  require Logger

  def localize(content_source, version, content_changes) do
    updates =
      content_changes
      |> Enum.flat_map(fn module -> localize_module(content_source, module, version) end)

    {title, description} = {"Localization", "Localization is done"}

    %{
      title: title,
      description: description,
      content: Enum.map(updates, fn {id, content, _summary} -> [id: id, content: content] end)
    }
  end

  def title_and_description_from_summaries(_summaries) do
    {"Localization", "Localization is done"}
  end

  def localize_module(content_source, module, version) do
    {:ok, source_content} =
      ContentSources.get_content(content_source, module[:source][:id], {:version, version})

    Enum.map(module[:target], fn {type, target} ->
      localize_localizable(
        target[:id],
        source_content,
        module[:source],
        module[:format],
        target,
        type
      )
    end)
  end

  def localize_localizable(id, source_content, source, format, target, :new_target_localizable) do
    llm = LLMs.default()

    {:ok, %{choices: [%{message: %{content: content}} | _]}} =
      llm.complete_chat("gpt-4", [
        %{
          content: """
          You are a linguistic that works for Apple localizing apps and marketing websites.
          Your role is to transcreate the given content in language #{source[:context][:language]} into the language #{target[:context][:language]}.
          You are given the content in format #{format} between the markers <--CONTENT_START--> and <--CONTENT_END-->.
          You have to return the content between the markers <--CONTENT_START--> and <--CONTENT_END--> and a summary of the content being transcreated between the markers <--SUMMARY_START--> and <--SUMMARY_END-->.
          Use comments to contextualize the underlying content and leave the comments untouched in the transcreated content.
          Be gender neutral when possible.
          """,
          role: :system
        },
        %{
          content: """
          Transcreate the content:
          <--CONTENT_START-->
          #{source_content}
          <--CONTENT_END-->
          """,
          role: :user
        }
      ])

    Logger.info(content)

    {:ok, extracted_content} = extract(content, :content)
    {:ok, extracted_summary} = extract(content, :summary)

    {id, extracted_content, extracted_summary}
  end

  def extract(text, token) do
    stringified_token = String.upcase(Atom.to_string(token))
    pattern = ~r/<--#{stringified_token}_START-->(.*?)<--#{stringified_token}_END-->/s

    case Regex.scan(pattern, text) do
      [[_full_match, content]] -> {:ok, content}
      _ -> {:error, "Content not found"}
    end
  end
end
