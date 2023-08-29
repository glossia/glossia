defmodule Glossia.Features.LLMs.OpenAIChatGPT do
  @behaviour Glossia.Foundation.LLMs.Behaviors.LLM

  # Impl:  Glossia.Foundation.LLMs.Behaviors.LLM

  @impl Glossia.Foundation.LLMs.Behaviors.LLM
  def complete_chat(model, messages) when is_list(messages) do
    req =
      Req.new(
        url: "https://api.openai.com/v1/chat/completions",
        method: :post,
        receive_timeout: default_timeout(),
        auth: {:bearer, api_key()},
        json: %{
          model: model,
          messages: messages
        }
      )

    case Req.request(req) do
      {:ok, %{body: body}} -> {:ok, Useful.atomize_map_keys(body)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp default_timeout() do
    200_000
  end

  @impl Glossia.Foundation.LLMs.Behaviors.LLM
  def configured?() do
    api_key() != ""
  end

  defp api_key() do
    case Application.get_env(:glossia, :openai_chatgpt_secret_key) do
      "" -> raise "OpenAI ChatGPT secret key not configured"
      key -> key
    end
  end
end
