defmodule Glossia.Features.LLMs.OpenAIChatGPT do
  @behaviour Glossia.Foundation.LLMs.Behaviors.LLM

  # Struct
  defstruct [:api_key]

  def new() do
    %__MODULE__{
      api_key: api_key()
    }
  end

  # Modules
  alias OpenaiEx.ChatCompletion
  alias OpenaiEx.ChatMessage

  @impl true
  def complete_chat(llm, model, messages) when is_list(messages) and llm.api_key != "" do
    chat_completion =
      ChatCompletion.new(
        model: model,
        messages:
          messages
          |> Enum.map(fn message ->
            %{role: Atom.to_string(message.role), content: message.content}
          end)
      )

    llm.api_key |> OpenaiEx.new() |> ChatCompletion.create(chat_completion)
  end

  def complete_chat(llm, _, _) when llm.api_key == "" do
    {:error, "OPEN_API_KEY environment variable not present"}
  end

  @impl true
  def configured?() do
    api_key() != ""
  end

  defp api_key() do
    Application.get_env(:glossia, :open_api_key)
  end
end
