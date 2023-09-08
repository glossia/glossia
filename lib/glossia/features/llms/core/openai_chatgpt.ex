defmodule Glossia.Features.LLMs.Core.OpenAIChatGPT do
  @behaviour Glossia.Foundation.LLMs.Core.LLM

  @impl true
  def complete_chat(model, messages, opts \\ []) when is_list(messages) do
    temperature = Keyword.get(opts, :temperature, 0.2)
    req =
      Req.new(
        url: "https://api.openai.com/v1/chat/completions",
        method: :post,
        receive_timeout: default_timeout(),
        auth: {:bearer, api_key()},
        json: %{
          model: model,
          messages: messages,
          temperature: temperature
        }
      )

    # "prompt_tokens": 9,
    # "completion_tokens": 12,
    case Req.request(req) do
      {:ok, %{body: body}} ->
        atomized_body = Useful.atomize_map_keys(body)
        {:ok, %{payload: atomized_body, cost: get_cost(atomized_body[:usage], model)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_cost(usage, model) do
    %{
      input_tokens: usage[:prompt_tokens],
      input_price_usd: usage[:prompt_tokens] * input_token_price(model),
      output_tokens: usage[:completion_tokens],
      output_price_usd: usage[:completion_tokens] * output_token_price(model)
    }
  end

  def input_token_price("gpt-4") do
    0.003 / 1000
  end

  def output_token_price("gpt-4") do
    0.006 / 1000
  end

  defp default_timeout() do
    200_000
  end

  @impl true
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
