defmodule GlossiaWeb.Api.LLMProxyController do
  @moduledoc """
  Proxies LLM requests through Glossia, acting as a broker.

  The CLI sends a request with the account handle and model handle,
  and Glossia resolves the model configuration (provider, model ID,
  API key) and forwards the request to the appropriate LLM provider
  via req_llm.
  """

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.LLMModels
  alias GlossiaWeb.ApiAuthorization

  def generate(conn, %{"handle" => handle, "model_handle" => model_handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_read, account) do
          {:ok, conn} ->
            case LLMModels.get_model_by_handle(model_handle, account.id) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "model not found"})

              model ->
                proxy_request(conn, model, params)
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp proxy_request(conn, model, params) do
    prompt = params["prompt"] || params["messages"]
    opts = build_opts(params, model.api_key)

    case do_generate(model.model, prompt, opts) do
      {:ok, response} ->
        conn |> json(%{result: serialize_response(response)})

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "llm_request_failed", detail: inspect(reason)})
    end
  end

  defp do_generate(model_id, prompt, opts) when is_binary(prompt) do
    try do
      response = ReqLLM.generate_text(model_id, prompt, opts)
      {:ok, response}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp do_generate(model_id, messages, opts) when is_list(messages) do
    try do
      response = ReqLLM.generate_text(model_id, messages, opts)
      {:ok, response}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp do_generate(_model_id, nil, _opts) do
    {:error, "missing prompt or messages parameter"}
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

    opts =
      case params["system"] do
        s when is_binary(s) and s != "" -> Keyword.put(opts, :system, s)
        _ -> opts
      end

    opts
  end

  defp serialize_response(response) do
    %{
      text: Map.get(response, :text, ""),
      usage: serialize_usage(Map.get(response, :usage))
    }
  end

  defp serialize_usage(nil), do: nil

  defp serialize_usage(usage) do
    %{
      input_tokens: Map.get(usage, :input_tokens),
      output_tokens: Map.get(usage, :output_tokens),
      total_cost: Map.get(usage, :total_cost)
    }
  end
end
