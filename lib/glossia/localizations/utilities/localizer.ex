defmodule Glossia.Localizations.Utilities.Localizer do
  @moduledoc false

  alias Glossia.LLMs, as: LLMs
  alias Glossia.Localizations.Utilities.Prompts
  alias Glossia.Localizations.Utilities.Parser
  alias Glossia.Localizations.Utilities.Checksum
  require Logger

  @task_timeout 120_000

  def localize(content_source, content_source_id, version, content_changes) do
    updates =
      content_changes
      |> Enum.map(fn module ->
        Task.Supervisor.async(Glossia.TaskSupervisor, fn ->
          __MODULE__.localize_module(content_source, content_source_id, module, version)
        end)
      end)
      |> Enum.map(fn task ->
        Task.await(task, @task_timeout)
      end)
      |> Enum.flat_map(& &1)

    summaries =
      Enum.map(updates, fn {_, _, summary} -> summary end) |> Enum.filter(fn x -> x != nil end)

    {_title, _description} = title_and_description_from_summaries(summaries)

    # Disabled
    # %{
    #   title: title,
    #   description: description,
    #   content: Enum.map(updates, fn {id, content, _} -> [id: id, content: content] end)
    # }
  end

  def title_and_description_from_summaries(summaries) do
    llm = LLMs.default()

    prompt =
      Prompts.get_title_and_description_prompt_for_summaries(summaries, :title, :description)

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: _cost}} =
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

  def localize_module(content_source, content_source_id, module, version) do
    {:ok, source_content} =
      content_source.get_content(
        content_source_id,
        module[:source][:id],
        version
      )

    target_updates =
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
      |> Enum.flat_map(& &1)

    source_checksum_content =
      %{
        algorithm: Atom.to_string(hashing_algorithm()),
        value: Checksum.get_source_content_checksum(source_content, hashing_algorithm())
      }
      |> Jason.encode!()

    [
      {module[:source][:checksum_cache_id], source_checksum_content, nil}
      | target_updates
    ]
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

    prompt =
      Prompts.get_localize_prompt(
        source_content,
        source,
        format,
        target,
        type,
        :content,
        :summary
      )

    {:ok, %{payload: %{choices: [%{message: %{content: content}} | _]}, cost: _cost}} =
      llm.complete_chat("gpt-4", [
        %{
          content: prompt,
          role: :user
        }
      ])

    {:ok, extracted_content} = Parser.parse_llm_output(content, :content)
    {:ok, extracted_summary} = Parser.parse_llm_output(content, :summary)

    checksum_content =
      %{
        value:
          Checksum.get_localized_content_checksum(
            source_content,
            source,
            format,
            target,
            type,
            hashing_algorithm()
          ),
        algorithm: Atom.to_string(hashing_algorithm())
      }
      |> Jason.encode!()

    [
      {id, extracted_content, extracted_summary},
      {target[:checksum_cache_id], checksum_content, nil}
    ]
  end

  def hashing_algorithm do
    :sha256
  end
end
