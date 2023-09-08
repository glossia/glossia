defmodule Glossia.Foundation.Localizations.Core.Utilities.Localizer do
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.LLMs.Core, as: LLMs
  alias Glossia.Foundation.Localizations.Core.Utilities.Prompts
  alias Glossia.Foundation.Localizations.Core.Utilities.Parser
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
        Task.await(task, @task_timeout)
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

    prompt =
      Prompts.get_title_and_description_prompt_for_summaries(summaries, :title, :description)

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: cost}} =
      llm.complete_chat("gpt-4", [
        %{
          content: prompt,
          role: :user
        }
      ])

    {:ok, extracted_title} = Parser.parse_llm_output(content, :title)
    {:ok, extracted_description} = Parser.parse_llm_output(content, :description)

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
      Task.await(task, @task_timeout)
    end)
  end

  def localize_localizable(
        id,
        source_content,
        source,
        format,
        target,
        :new_target_localizable = type
      ) do
    llm = LLMs.default()

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: cost}} =
      llm.complete_chat("gpt-4", [
        %{
          content:
            Prompts.get_localize_prompt(
              source_content,
              source,
              format,
              target,
              type,
              :content,
              :summary
            ),
          role: :user
        }
      ])

    {:ok, extracted_content} = Parser.parse_llm_output(content, :content)
    {:ok, extracted_summary} = Parser.parse_llm_output(content, :summary)

    {id, extracted_content, extracted_summary}
  end
end
