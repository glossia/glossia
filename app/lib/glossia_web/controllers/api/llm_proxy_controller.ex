defmodule GlossiaWeb.Api.LLMProxyController do
  @moduledoc """
  OpenAI-compatible completion endpoints that proxy through account-configured models.

  Clients point any OpenAI-compatible SDK at:

      POST /api/:handle/v1/chat/completions
      POST /api/:handle/v1/completions

  The `model` field in the request body is resolved as the account's model handle.
  Glossia looks up the real provider and API key, forwards the request, and returns
  the response in standard OpenAI format.
  """

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.LLMModels
  alias GlossiaWeb.ApiAuthorization

  def chat_completions(conn, %{"handle" => handle} = params) do
    with {:ok, conn, model} <- resolve_model(conn, handle, params["model"]) do
      messages = params["messages"] || []
      opts = build_opts(params, model.api_key)

      case generate(model.model, messages, opts) do
        {:ok, response} ->
          conn |> json(to_chat_completion_response(response, params["model"]))

        {:error, reason} ->
          conn |> put_status(:bad_gateway) |> json(error_response(reason))
      end
    end
  end

  def completions(conn, %{"handle" => handle} = params) do
    with {:ok, conn, model} <- resolve_model(conn, handle, params["model"]) do
      prompt = params["prompt"] || ""
      opts = build_opts(params, model.api_key)

      case generate(model.model, prompt, opts) do
        {:ok, response} ->
          conn |> json(to_completion_response(response, params["model"]))

        {:error, reason} ->
          conn |> put_status(:bad_gateway) |> json(error_response(reason))
      end
    end
  end

  defp resolve_model(conn, handle, model_handle) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(error_response("account not found"))
        |> halt()

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_read, account) do
          {:ok, conn} ->
            case LLMModels.get_model_by_handle(model_handle, account.id) do
              nil ->
                conn
                |> put_status(:not_found)
                |> json(
                  error_response(
                    "model '#{model_handle}' not found — configure it in account settings"
                  )
                )
                |> halt()

              model ->
                {:ok, conn, model}
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp generate(model_id, input, opts) do
    try do
      response = ReqLLM.generate_text(model_id, input, opts)
      {:ok, response}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp build_opts(params, api_key) do
    opts = [api_key: api_key]

    opts =
      case params["max_tokens"] do
        n when is_integer(n) and n > 0 -> Keyword.put(opts, :max_tokens, n)
        _ -> opts
      end

    opts =
      case params["temperature"] do
        t when is_number(t) -> Keyword.put(opts, :temperature, t)
        _ -> opts
      end

    case params["top_p"] do
      p when is_number(p) -> Keyword.put(opts, :top_p, p)
      _ -> opts
    end
  end

  defp to_chat_completion_response(response, model) do
    text = Map.get(response, :text, "")
    usage = Map.get(response, :usage)

    %{
      id: "chatcmpl-#{System.unique_integer([:positive])}",
      object: "chat.completion",
      created: System.system_time(:second),
      model: model,
      choices: [
        %{
          index: 0,
          message: %{role: "assistant", content: text},
          finish_reason: "stop"
        }
      ],
      usage: format_usage(usage)
    }
  end

  defp to_completion_response(response, model) do
    text = Map.get(response, :text, "")
    usage = Map.get(response, :usage)

    %{
      id: "cmpl-#{System.unique_integer([:positive])}",
      object: "text_completion",
      created: System.system_time(:second),
      model: model,
      choices: [
        %{
          index: 0,
          text: text,
          finish_reason: "stop"
        }
      ],
      usage: format_usage(usage)
    }
  end

  defp format_usage(nil), do: %{prompt_tokens: 0, completion_tokens: 0, total_tokens: 0}

  defp format_usage(usage) do
    input = Map.get(usage, :input_tokens, 0) || 0
    output = Map.get(usage, :output_tokens, 0) || 0

    %{
      prompt_tokens: input,
      completion_tokens: output,
      total_tokens: input + output
    }
  end

  defp error_response(reason) do
    %{
      error: %{
        message: if(is_binary(reason), do: reason, else: inspect(reason)),
        type: "api_error",
        code: nil
      }
    }
  end

end
