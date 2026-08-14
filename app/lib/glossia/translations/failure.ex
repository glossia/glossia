defmodule Glossia.Translations.Failure do
  @moduledoc """
  Converts translation failures into a small, safe value for progress events.

  Provider exceptions may carry request bodies, response bodies, headers, and
  stack traces. This module deliberately keeps only fields that are safe and
  useful to show to an account member.
  """

  @type t :: %{
          kind: String.t(),
          scope: String.t(),
          provider: String.t() | nil,
          status: pos_integer() | nil,
          code: String.t() | nil,
          request_id: String.t() | nil
        }

  @known_kinds ~w(
    provider-credit
    provider-rate-limit
    provider-credentials
    provider-timeout
    provider-error
    validation-syntax
    validation-preserved-content
    validation-command
    validation
    source-invalid-encoding
    source-unreadable
    translation-failed
  )

  @provider_kinds ~w(
    provider-credit
    provider-rate-limit
    provider-credentials
    provider-timeout
    provider-error
  )

  @retryable_kinds ~w(
    provider-rate-limit
    provider-timeout
    provider-error
  )

  @search_keys ~w(reason message error errors response_body cause code type status)
  @nested_error_keys ~w(reason error errors response_body cause headers)
  @request_id_keys ~w(x-request-id request-id openai-request-id)

  @doc "Builds a safe failure from an engine error."
  @spec from(term(), term()) :: t()
  def from(reason, provider \\ nil)

  def from({:llm_failed, reason}, provider), do: provider_failure(reason, provider)

  def from({:validation_failed, reason}, _provider) do
    failure(validation_kind(searchable_text(reason)), "item")
  end

  def from(:source_invalid_encoding, _provider),
    do: failure("source-invalid-encoding", "item")

  def from({:source_unreadable, _reason}, _provider),
    do: failure("source-unreadable", "item")

  def from(reason, provider) when is_binary(reason) do
    normalized = String.downcase(reason)

    cond do
      reason == "source file contains invalid text encoding" ->
        failure("source-invalid-encoding", "item")

      provider_signal?(normalized) ->
        provider_failure(reason, provider)

      validation_signal?(normalized) ->
        failure(validation_kind(normalized), "item")

      true ->
        failure("translation-failed", "item")
    end
  end

  def from(_reason, _provider), do: failure("translation-failed", "item")

  @doc """
  Revalidates a failure received over progress messaging.

  Legacy string reasons are classified but never retained.
  """
  @spec normalize(term()) :: t()
  def normalize(reason)

  def normalize(%{} = failure) do
    kind = safe_kind(map_value(failure, :kind))
    scope = if kind in @provider_kinds, do: "session", else: "item"

    failure(kind, scope,
      provider: safe_provider(map_value(failure, :provider)),
      status: safe_status(map_value(failure, :status)),
      code: safe_identifier(map_value(failure, :code), 80),
      request_id: safe_identifier(map_value(failure, :request_id), 200)
    )
  end

  def normalize(reason), do: from(reason)

  @doc """
  Whether a failure is worth retrying.

  Rate limits, timeouts, and unclassified provider/transport errors are
  transient. Exhausted credit and bad credentials are not - retrying those only
  burns time and produces the same failure. Neither is a client-side 4xx: an
  unknown model, a malformed request, or content the provider rejects fails the
  same way every time, so only 408 and 429 stay retryable in that range.
  """
  def retryable?(%{kind: kind} = failure),
    do: kind in @retryable_kinds and not permanent_status?(Map.get(failure, :status))

  def retryable?(_failure), do: false

  defp permanent_status?(status) when is_integer(status),
    do: status >= 400 and status < 500 and status not in [408, 429]

  defp permanent_status?(_status), do: false

  @doc "Whether a failure should also have a session-level summary."
  @spec session_level?(t()) :: boolean()
  def session_level?(%{scope: "session"}), do: true
  def session_level?(_failure), do: false

  defp provider_failure(reason, provider) do
    text = searchable_text(reason)
    normalized = String.downcase(text)
    status = extract_status(reason, text)

    kind =
      cond do
        status == 402 or
            (status != 429 and
               contains_any?(normalized, [
                 "credit limit",
                 "insufficient credit",
                 "usage limit",
                 "purchase more credits"
               ])) ->
          "provider-credit"

        status == 429 or
            contains_any?(normalized, ["rate limit", "too many requests", "throttl"]) ->
          "provider-rate-limit"

        status in [401, 403] or
            contains_any?(normalized, [
              "unauthorized",
              "invalid api key",
              "invalid authentication",
              "authentication failed",
              "credentials"
            ]) ->
          "provider-credentials"

        contains_any?(normalized, ["timed out", "timeout", "checkout timeout"]) ->
          "provider-timeout"

        true ->
          "provider-error"
      end

    failure(kind, "session",
      provider: safe_provider(provider),
      status: status,
      code: extract_code(reason, text),
      request_id: extract_request_id(reason, text)
    )
  end

  defp validation_kind(text) do
    normalized = String.downcase(text)

    cond do
      contains_any?(normalized, [
        "invalid json",
        "invalid yaml",
        "frontmatter invalid",
        "po file",
        "po entry",
        "po invalid",
        "po has "
      ]) ->
        "validation-syntax"

      contains_any?(normalized, [
        "preserved tokens missing",
        "unexpected preserved tokens",
        "protected token marker"
      ]) ->
        "validation-preserved-content"

      contains_any?(normalized, [
        "external check failed",
        "validation failed: exit"
      ]) ->
        "validation-command"

      true ->
        "validation"
    end
  end

  defp validation_signal?(text) do
    contains_any?(text, [
      "validation failed",
      "external check failed",
      "invalid json",
      "invalid yaml",
      "frontmatter invalid",
      "preserved token",
      "po file",
      "po entry",
      "po invalid"
    ])
  end

  defp provider_signal?(text) do
    contains_any?(text, [
      "model request failed",
      "credit limit",
      "rate limit",
      "too many requests",
      "unauthorized",
      "invalid api key",
      "authentication",
      "provider",
      "timed out",
      "timeout"
    ])
  end

  defp failure(kind, scope, opts \\ []) do
    %{
      kind: safe_kind(kind),
      scope: scope,
      provider: Keyword.get(opts, :provider),
      status: Keyword.get(opts, :status),
      code: Keyword.get(opts, :code),
      request_id: Keyword.get(opts, :request_id)
    }
  end

  defp safe_kind(kind) when kind in @known_kinds, do: kind
  defp safe_kind(_kind), do: "translation-failed"

  defp safe_provider(nil), do: nil

  defp safe_provider(provider) when is_atom(provider),
    do: provider |> Atom.to_string() |> safe_provider()

  defp safe_provider(provider) when is_binary(provider) do
    provider = String.downcase(provider)

    if Regex.match?(~r/^[a-z0-9_-]{1,40}$/, provider), do: provider
  end

  defp safe_provider(_provider), do: nil

  defp safe_status(status) when is_integer(status) and status >= 100 and status <= 599, do: status

  defp safe_status(status) when is_binary(status) do
    case Integer.parse(status) do
      {value, ""} -> safe_status(value)
      _ -> nil
    end
  end

  defp safe_status(_status), do: nil

  defp safe_identifier(nil, _max_length), do: nil

  defp safe_identifier(value, max_length) when is_atom(value) and is_boolean(value) == false,
    do: value |> Atom.to_string() |> safe_identifier(max_length)

  defp safe_identifier(value, max_length) when is_binary(value) do
    value = String.trim(value)

    if String.length(value) <= max_length and
         Regex.match?(~r/^[A-Za-z0-9_.:\/-]+$/, value),
       do: value
  end

  defp safe_identifier(_value, _max_length), do: nil

  defp extract_status(reason, text) do
    direct = find_value(reason, ["status"])

    safe_status(direct) ||
      case Regex.run(~r/(?:status(?:\\?"|")?\s*(?:=>|:)\s*)(\d{3})/i, text) do
        [_, status] -> safe_status(status)
        _ -> nil
      end
  end

  defp extract_code(reason, text) do
    direct =
      find_value(reason, ["code"])
      |> safe_identifier(80)
      |> reject_generic_code()

    type =
      find_value(reason, ["type"])
      |> safe_identifier(80)
      |> reject_generic_code()

    direct ||
      type ||
      case Regex.run(
             ~r/(?:code|type)(?:\\?"|")?\s*(?:=>|:)\s*(?:\\?"|")([A-Za-z0-9_.:\/-]{1,80})/i,
             text
           ) do
        [_, code] -> code |> safe_identifier(80) |> reject_generic_code()
        _ -> nil
      end
  end

  defp reject_generic_code(code) when code in ["api", "error", "stream", "nil", "null"], do: nil
  defp reject_generic_code(code), do: code

  defp extract_request_id(reason, text) do
    direct =
      reason
      |> find_header_value(@request_id_keys)
      |> safe_identifier(200)

    direct ||
      case Regex.run(
             ~r/(?:x-request-id|request-id|openai-request-id)(?:\\?"|")?\s*(?:=>|,|:)\s*(?:\\?"|")([A-Za-z0-9_.:\/-]{1,200})/i,
             text
           ) do
        [_, request_id] -> safe_identifier(request_id, 200)
        _ -> nil
      end
  end

  defp find_value(%_{} = struct, keys), do: struct |> struct_fields() |> find_value(keys)

  defp find_value(%{} = map, keys) do
    direct =
      Enum.find_value(map, fn {key, value} ->
        if normalized_key(key) in keys and not is_nil(value), do: value
      end)

    direct ||
      Enum.find_value(map, fn {key, value} ->
        if normalized_key(key) in @nested_error_keys, do: find_value(value, keys)
      end)
  end

  defp find_value(list, keys) when is_list(list),
    do: Enum.find_value(list, &find_value(&1, keys))

  defp find_value(tuple, keys) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> Enum.find_value(&find_value(&1, keys))

  defp find_value(_value, _keys), do: nil

  defp find_header_value(%_{} = struct, keys),
    do: struct |> struct_fields() |> find_header_value(keys)

  defp find_header_value(%{} = map, keys) do
    direct =
      Enum.find_value(map, fn {key, value} ->
        if normalized_key(key) in keys, do: value
      end)

    direct ||
      Enum.find_value(map, fn {key, value} ->
        if normalized_key(key) in @nested_error_keys,
          do: find_header_value(value, keys)
      end)
  end

  defp find_header_value([{key, value} | rest], keys) do
    if normalized_key(key) in keys,
      do: value,
      else: find_header_value(rest, keys)
  end

  defp find_header_value([value | rest], keys),
    do: find_header_value(value, keys) || find_header_value(rest, keys)

  defp find_header_value(tuple, keys) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> find_header_value(keys)

  defp find_header_value(_value, _keys), do: nil

  defp searchable_text(value),
    do: value |> searchable_parts() |> Enum.join(" ") |> String.slice(0, 50_000)

  defp searchable_parts(value) when is_binary(value), do: [value]
  defp searchable_parts(value) when is_atom(value), do: [Atom.to_string(value)]
  defp searchable_parts(value) when is_number(value), do: [to_string(value)]

  defp searchable_parts(%_{} = struct), do: struct |> struct_fields() |> searchable_parts()

  defp searchable_parts(%{} = map) do
    Enum.flat_map(map, fn {key, value} ->
      if normalized_key(key) in @search_keys, do: searchable_parts(value), else: []
    end)
  end

  defp searchable_parts(list) when is_list(list),
    do: list |> Enum.take(100) |> Enum.flat_map(&searchable_parts/1)

  defp searchable_parts(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> Enum.flat_map(&searchable_parts/1)

  defp searchable_parts(_value), do: []

  # Provider errors often arrive as structs (`ReqLLM.Error.API.Request`,
  # `Req.TransportError`). A struct matches the map pattern but is not
  # enumerable, so its fields are read explicitly rather than crashing the run.
  defp struct_fields(%_{} = struct), do: struct |> Map.from_struct() |> Map.drop([:__exception__])

  defp normalized_key(key) when is_atom(key), do: key |> Atom.to_string() |> normalized_key()
  defp normalized_key(key) when is_binary(key), do: String.downcase(key)
  defp normalized_key(_key), do: ""

  defp map_value(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp contains_any?(text, needles), do: Enum.any?(needles, &String.contains?(text, &1))
end
