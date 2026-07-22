defmodule Glossia.Models.ModelIdentifier do
  @moduledoc """
  Normalizes model identifiers to the `provider/model` form used by models.dev
  and OpenCode.

  ReqLLM still accepts `provider:model`, so callers that cross that boundary
  should use `to_req_llm/1` instead of changing the stored identifier.
  """

  @canonical_pattern ~r/^[a-z0-9_-]+\/.+$/

  @spec normalize(term()) :: term()
  def normalize(identifier) when is_binary(identifier) do
    identifier = String.trim(identifier)

    case String.split(identifier, ":", parts: 2) do
      [provider, model] when provider != "" and model != "" ->
        if String.contains?(provider, "/"), do: identifier, else: join(provider, model)

      _ ->
        identifier
    end
  end

  def normalize(identifier), do: identifier

  @spec valid?(term()) :: boolean()
  def valid?(identifier) when is_binary(identifier),
    do: Regex.match?(@canonical_pattern, identifier)

  def valid?(_identifier), do: false

  @spec split(term()) :: {:ok, {String.t(), String.t()}} | :error
  def split(identifier) when is_binary(identifier) do
    case identifier |> normalize() |> String.split("/", parts: 2) do
      [provider, model] when provider != "" and model != "" -> {:ok, {provider, model}}
      _ -> :error
    end
  end

  def split(_identifier), do: :error

  @spec join(atom() | String.t(), String.t()) :: String.t()
  def join(provider, model), do: "#{provider}/#{model}"

  @spec provider(term()) :: String.t()
  def provider(identifier) do
    case split(identifier) do
      {:ok, {provider, _model}} -> provider
      :error -> ""
    end
  end

  @spec provider_model(term()) :: String.t()
  def provider_model(identifier) do
    case split(identifier) do
      {:ok, {_provider, model}} -> model
      :error when is_binary(identifier) -> identifier
      :error -> ""
    end
  end

  @spec to_req_llm(term()) :: term()
  def to_req_llm(identifier) do
    case split(identifier) do
      {:ok, {provider, model}} -> "#{provider}:#{model}"
      :error -> identifier
    end
  end
end
