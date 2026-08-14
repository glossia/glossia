defmodule GlossiaWeb.Api.TranslationController do
  @moduledoc """
  Content translation endpoint.

      POST /api/:handle/translate

  Accepts a single translation work item and returns the translated content, the
  resolved model, and token usage. The prompt construction and the model call
  happen server-side (`Glossia.Translations`); clients only send source content
  and receive translations.
  """

  use GlossiaWeb, :controller

  alias Glossia.Translations

  plug GlossiaWeb.Plugs.AuthorizeAccount, :translation_write

  def create(conn, params) do
    case Translations.translate(conn.assigns.account, params) do
      {:ok, result} ->
        json(conn, %{
          text: result.text,
          model: result.model,
          model_handle: result.model_handle,
          provider: result.provider
        })

      {:error, {:model_not_found, model_handle}} ->
        conn
        |> put_status(:not_found)
        |> json(
          error_response("model '#{model_handle}' not found — configure it in account settings")
        )

      {:error, {:missing_field, field}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(error_response("missing required field: #{field}"))

      {:error, {:invalid_format, format}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(error_response("unsupported format: #{format}"))

      {:error, {:llm_failed, reason}} ->
        conn
        |> put_status(:bad_gateway)
        |> json(error_response(reason))
    end
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
