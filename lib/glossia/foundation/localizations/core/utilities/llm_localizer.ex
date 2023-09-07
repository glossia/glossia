defmodule Glossia.Foundation.Localizations.Core.Utilities.Localizer do
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

    summaries = Enum.map(updates, fn {_, _, summary} -> summary end)
    {title, description} = title_and_description_from_summaries(summaries)

    %{
      title: title,
      description: description,
      content: Enum.map(updates, fn {id, content, _} -> [id: id, content: content] end)
    }
  end

  def title_and_description_from_summaries(summaries) do
    llm = LLMs.default()

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: cost}} =
      llm.complete_chat("gpt-4", [
        %{
          content: """
          You are a linguistic that works for Apple creating content for apps and marketing websites.
          You are given a list of summaries of localization work that has happenend.
          Come up with a 60-character title and return it between the markers <--TITLE_START--> and <--TITLE_END-->, and a description and return it between the markers <--DESCRIPTION_START--> and <--DESCRIPTION_END-->.
          Here are the summaries of the work:
          #{Enum.join(Enum.map(summaries, fn summary -> "- #{summary}" end), "\n")}
          """,
          role: :user
        }
      ])

    {:ok, extracted_title} = extract(content, :title)
    {:ok, extracted_description} = extract(content, :description)

    {extracted_title, extracted_description}
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
          You are given the content in format #{format} between the markers <--CONTENT_START--> and <--CONTENT_END--> and you have to return the content between the markers <--CONTENT_START--> and <--CONTENT_END-->.
          Include a summary about the content being localized and the source and target languages between the markers <--SUMMARY_START--> and <--SUMMARY_END-->.
          Be gender neutral when localizing the following content:
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
