defmodule Glossia.Foundation.Localizations.Core.Utilities.Prompts do
  alias Glossia.Foundation.Localizations.Core.Utilities.Parser
  alias Glossia.Foundation.Localizations.Core.Utilities.Languages

  def get_title_and_description_prompt_for_summaries(summaries, title_token, description_token)
      when is_list(summaries) do
    """
    You are an English linguistic and you are given a list of summaries of localization work that has happened.
    Write a 60-character title and return it between the markers #{Parser.get_llm_content_start_delimiter(title_token)} and #{Parser.get_llm_content_end_delimiter(title_token)}, and a description and return it between the markers #{Parser.get_llm_content_start_delimiter(description_token)} and #{Parser.get_llm_content_end_delimiter(description_token)}.
    Here are the summaries of the work:
    #{Enum.join(Enum.map(summaries, fn summary -> "- #{summary}" end), "\n")}
    """
  end

  def get_localize_prompt(
        source_content,
        source,
        format,
        target,
        :new_target_localizable,
        content_token,
        summary_token
      ) do
    source_language_name = Languages.get_language_from_iso_639_1_code(source[:context][:language])
    target_language_name = Languages.get_language_from_iso_639_1_code(target[:context][:language])

    """
    You are a linguistic that speaks #{source_language_name} and #{target_language_name} natively.
    Your role is to localize the given content in language #{source[:context][:language]} into the language #{target[:context][:language]}.
    #{get_content_comments_sentence(format)}
    You are given the content in format #{format} between the markers #{Parser.get_llm_content_start_delimiter(content_token)} and #{Parser.get_llm_content_end_delimiter(content_token)} and you have to return the content between the markers #{Parser.get_llm_content_start_delimiter(content_token)} and #{Parser.get_llm_content_end_delimiter(content_token)}.
    Include a summary about the content being localized and the source and target languages between the markers #{Parser.get_llm_content_start_delimiter(summary_token)} and #{Parser.get_llm_content_end_delimiter(summary_token)}.
    Be gender neutral when localizing the following content:
    #{Parser.get_llm_content_start_delimiter(content_token)}
    #{source_content}
    #{Parser.get_llm_content_end_delimiter(content_token)}
    """
  end

  defp get_content_comments_sentence("portable-object") do
    "Ignore the lines that start with #"
  end

  defp get_content_comments_sentence(_format) do
    "From the given content, leave comments untouched. In other words, you localize the lines that contain a key-value pair representing a piece of content."
  end
end
