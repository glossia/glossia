defmodule Glossia.Foundation.LLMs.Core.LLM do
  @type chat_completion_role_t :: :system | :user | :assistant | :function

  @type chat_message_t :: %{
          content: String.t(),
          role: chat_completion_role_t()
        }
  @type chat_completion_t :: %{
          id: String.t(),
          created: number(),
          model: String.t(),
          choices: [chat_completion_choice_t()],
          usage: %{
            prompt_tokens: number(),
            completion_tokens: number(),
            total_tokens: number()
          }
        }
  @type chat_completion_choice_t :: %{
          index: number(),
          message: %{
            role: chat_completion_role_t(),
            content: String.t()
          }
        }

  @doc """
  It completes a chat conversation using the given model and messages.

  ## Parameters
  - `model` - The model to use for completion.
  - `messages` - The messages to use for completion.
  """
  @callback complete_chat(model :: String.t(), messages :: [chat_message_t()]) ::
              {:ok, chat_completion_t()}

  @doc """
  It returns true if the given model is configured, false otherwise.
  """
  @callback configured?() :: boolean()
end
