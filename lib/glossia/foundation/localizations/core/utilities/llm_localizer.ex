defmodule Glossia.Foundation.Localizations.Core.Utilities.LLMLocalizer do
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.LLMs.Core, as: LLMs
  require Logger

  @task_timeout 120_000

  def localize(content_source, version, content_changes) do
    updates =
      content_changes
      |> Enum.map(fn module ->
        Task.Supervisor.async(Glossia.TaskSupervisor, fn ->
          __MODULE__.localize_module(content_source, module, version)
        end)
      end)
      |> Enum.map(fn task ->
        Task.await(task,  @task_timeout)
      end)
      |> Enum.flat_map(& &1)

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
      Task.Supervisor.async(Glossia.TaskSupervisor, fn ->
        __MODULE__.localize_localizable(
          target[:id],
          source_content,
          module[:source],
          module[:format],
          target,
          type
        )
      end)
    end)
    |> Enum.map(fn task ->
      Task.await(task,  @task_timeout)
    end)
  end

  def localize_localizable(id, source_content, source, format, target, :new_target_localizable) do
    llm = LLMs.default()

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: cost}} =
      llm.complete_chat("gpt-4", [
        %{
          content: """
          You are a linguistic that works for Apple creating content for apps and marketing websites.
          Your role is to localize the given content in language #{source[:context][:language]} into the language #{target[:context][:language]}.
          Comments start with #, are not localized, and they represent the context of the content below.
          You are given the content in format #{format} between the markers <--CONTENT_START--> and <--CONTENT_END--> and you have to return the content between the markers <--CONTENT_START--> and <--CONTENT_END--> and a summary of the content being localized between the markers <--SUMMARY_START--> and <--SUMMARY_END-->. Please, be gender neutral when localizing the following content:
          <--CONTENT_START-->
          #{source_content}
          <--CONTENT_END-->
          """,
          role: :user
        }
      ])

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
