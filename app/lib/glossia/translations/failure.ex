defmodule Glossia.Translations.Failure do
  @moduledoc """
  Converts translation failures into a small, safe value for progress events.

  Provider exceptions may carry request bodies, response bodies, headers, and
  stack traces. This module deliberately keeps only fields that are safe and
  useful to show to an account member.
  """

  # Match only the validator-owned prefix, and emit that constant rather than
  # the original message. Suffixes can contain source text, tokens, parser
  # excerpts, or arbitrary repository command output.
  @validation_reasons [
    {"markdown-literal-array-shape",
     "Markdown text-literal recovery must return a JSON string array of matching length"},
    {"markdown-literal-array-syntax", "Markdown text-literal recovery returned invalid JSON"},
    {"markdown-literal-empty", "Markdown text-node recovery produced an empty translation"},
    {"markdown-literal-changed",
     "Markdown text-node recovery changed or emptied a source literal"},
    {"markdown-literal-count", "Markdown text-node recovery did not match the source text nodes"},
    {"markdown-recovery-prepare", "Markdown could not be prepared for recovery"},
    {"markdown-recovery-assemble", "Markdown could not be reassembled"},
    {"markdown-source-parse", "source Markdown could not be parsed"},
    {"markdown-translation-parse", "translation Markdown could not be parsed"},
    {"markdown-recovery-no-text", "Markdown source had no text nodes for marker recovery"},
    {"markdown-recovery-empty", "Markdown recovery marker had an empty translation"},
    {"markdown-recovery-markers",
     "Markdown recovery markers were missing, duplicated, or reordered"},
    {"markdown-structure", "translated Markdown changed the document structure"},
    {"frontmatter-syntax", "markdown frontmatter invalid"},
    {"json-syntax", "invalid JSON"},
    {"yaml-syntax", "invalid YAML"},
    {"empty-output", "translated output was empty"},
    {"missing-preserved-tokens", "preserved tokens missing from output"},
    {"unexpected-preserved-tokens", "unexpected preserved tokens in output"},
    {"protected-marker-count", "protected token marker occurred"},
    {"protected-values-changed",
     "these protected token markers and web addresses must be copied byte-for-byte exactly once"},
    {"external-check-exit", "external check failed: exit"},
    {"validation-command-exit", "validation failed: exit"},
    {"catalog-source-entries", "po entries must preserve every source msgid exactly once"},
    {"catalog-missing-translation", "po entry missing msgstr"},
    {"catalog-syntax", "po invalid line"},
    {"catalog-format-string", "po format string"}
  ]

  @known_kinds ~w(
    provider-credit
    provider-rate-limit
    provider-credentials
    provider-timeout
    provider-error
    validation-syntax
    validation-empty-output
    validation-structure
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
  @retry_after_keys ~w(retry-after x-ratelimit-reset-requests x-ratelimit-reset-tokens)

  # A provider that states how long to wait knows better than any backoff curve
  # we could pick. Cap it so a malformed or hostile header cannot park a
  # translation for hours.
  @max_retry_after_ms :timer.minutes(5)

  @doc "Builds a safe failure from an engine error."
  def from(reason, provider \\ nil)

  def from({:llm_failed, reason}, provider), do: provider_failure(reason, provider)

  def from({:validation_failed, reason}, _provider) do
    text = searchable_text(reason)

    failure(validation_kind(text), "item")
    |> Map.merge(validation_diagnostics(text))
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
        from({:validation_failed, reason})

      true ->
        failure("translation-failed", "item")
    end
  end

  def from(_reason, _provider), do: failure("translation-failed", "item")

  @doc """
  Revalidates a failure received over progress messaging.

  Legacy string reasons are classified but never retained.
  """
  def normalize(reason)

  def normalize(%{} = failure) do
    status = safe_status(map_value(failure, :status))

    kind =
      failure
      |> map_value(:kind)
      |> safe_kind()
      |> normalize_provider_kind(status)

    scope = if kind in @provider_kinds, do: "session", else: "item"

    failure(kind, scope,
      provider: safe_provider(map_value(failure, :provider)),
      status: status,
      code: safe_identifier(map_value(failure, :code), 80),
      request_id: safe_identifier(map_value(failure, :request_id), 200),
      retry_after_ms: safe_retry_after_ms(map_value(failure, :retry_after_ms))
    )
    |> Map.merge(normalize_validation_diagnostics(failure, kind))
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
  def session_level?(%{scope: "session"}), do: true
  def session_level?(_failure), do: false

  @doc """
  Whether a failure ends the whole run rather than only its own file.

  A run shares one provider and one credential, so an exhausted balance or a
  rejected key fails every remaining file identically. Transient session-level
  failures - rate limits, timeouts, 5xx - are excluded, because another file or
  another attempt can still succeed.
  """
  def run_stopping?(failure), do: session_level?(failure) and not retryable?(failure)

  @doc """
  A sentence naming why a run stopped, for the session error a member reads.

  Counting the files a run could not translate describes the symptom and hides
  the cause. That is actively misleading once a run stops at the first permanent
  provider failure: "Translation failed for 1 file" sends a member to inspect a
  file that is perfectly fine, when the account is simply out of credit.
  """
  def describe(failure) do
    failure = normalize(failure)

    cause(failure.kind) <> provider_detail(failure) <> ". " <> remediation(failure.kind)
  end

  defp cause("provider-credit"),
    do: "The model provider rejected the translation because the account has no credit left"

  defp cause("provider-credentials"),
    do: "The model provider rejected the configured credentials"

  defp cause("provider-rate-limit"), do: "The model provider rate-limited the translation"

  defp cause("provider-timeout"),
    do: "The model provider stopped responding before the translation completed"

  defp cause("provider-error"), do: "The model provider returned an error"

  defp cause(_kind), do: "The translation could not be completed"

  defp provider_detail(%{provider: nil, status: nil}), do: ""

  defp provider_detail(%{provider: provider, status: status}) do
    detail =
      [provider, status && "HTTP #{status}"]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    " (" <> detail <> ")"
  end

  defp remediation("provider-credit"), do: "Add credits for the model provider and retry."

  defp remediation("provider-credentials"),
    do: "Check the account's model credentials and retry."

  defp remediation("provider-rate-limit"), do: "Retry once the provider's limit resets."

  defp remediation(_kind), do: "Please retry."

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

        permanent_status?(status) ->
          "provider-error"

        status == 408 or
            contains_any?(normalized, ["timed out", "timeout", "checkout timeout"]) ->
          "provider-timeout"

        true ->
          "provider-error"
      end

    failure(kind, "session",
      provider: safe_provider(provider),
      status: status,
      code: extract_code(reason, text),
      request_id: extract_request_id(reason, text),
      retry_after_ms: extract_retry_after_ms(reason)
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

      String.contains?(normalized, "translated output was empty") ->
        "validation-empty-output"

      String.contains?(normalized, "translated markdown changed the document structure") ->
        "validation-structure"

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

  defp validation_diagnostics(text) do
    normalized =
      text
      |> String.downcase()
      |> then(
        &Regex.replace(
          ~r/\Amarkdown recovery marker [0-9]+ had an empty translation/,
          &1,
          "markdown recovery marker had an empty translation"
        )
      )

    case Enum.find(@validation_reasons, fn {_code, prefix} ->
           String.starts_with?(normalized, String.downcase(prefix))
         end) do
      {code, message} ->
        %{validation_code: code, validation_message: message}
        |> Map.merge(command_exit_diagnostics(code, command_exit_status(text)))

      nil ->
        unknown_validation_diagnostics()
    end
  end

  # Reconstruct the explanation from the code at every messaging boundary.
  # Never trust a caller-supplied validation_message, even for a known code.
  defp normalize_validation_diagnostics(value, "validation" <> _) do
    code = map_value(value, :validation_code)

    case List.keyfind(@validation_reasons, code, 0) do
      {code, message} ->
        %{validation_code: code, validation_message: message}
        |> Map.merge(command_exit_diagnostics(code, map_value(value, :validation_exit_status)))

      nil ->
        unknown_validation_diagnostics()
    end
  end

  defp normalize_validation_diagnostics(_value, _kind), do: %{}

  defp command_exit_status(text) do
    case Regex.run(
           ~r/\A(?:external check failed|validation failed): exit ([0-9]{1,3})(?:\n|$)/,
           text
         ) do
      [_, status] -> String.to_integer(status)
      _ -> nil
    end
  end

  defp command_exit_diagnostics(code, status)
       when code in ["external-check-exit", "validation-command-exit"] and
              is_integer(status) and status in 0..255,
       do: %{validation_exit_status: status}

  defp command_exit_diagnostics(_code, _status), do: %{}

  defp unknown_validation_diagnostics do
    %{
      validation_code: "unclassified",
      validation_message:
        "Unrecognized validation failure; add a safe diagnostic for this validator"
    }
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
      "po invalid",
      "translated output was empty",
      "translated markdown changed the document structure"
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
      request_id: Keyword.get(opts, :request_id),
      retry_after_ms: Keyword.get(opts, :retry_after_ms)
    }
  end

  defp safe_kind(kind) when kind in @known_kinds, do: kind
  defp safe_kind(_kind), do: "translation-failed"

  defp normalize_provider_kind("provider-timeout", status) do
    if permanent_status?(status), do: "provider-error", else: "provider-timeout"
  end

  defp normalize_provider_kind(kind, _status), do: kind

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

  # Retry-After carries seconds. Both the numeric and the HTTP-date form are
  # legal and only the numeric one is worth honouring, so a date reads as absent
  # and the caller falls back to its own backoff.
  defp extract_retry_after_ms(reason) do
    case seconds_value(find_header_value(reason, @retry_after_keys)) do
      nil -> nil
      seconds -> cap_retry_after_ms(seconds * 1_000)
    end
  end

  defp seconds_value(seconds) when is_integer(seconds) and seconds > 0, do: seconds

  defp seconds_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {seconds, rest} ->
        if String.trim(rest) == "", do: seconds_value(seconds), else: nil

      :error ->
        nil
    end
  end

  defp seconds_value(_value), do: nil

  # A failure that has already been through `from/2` states milliseconds, so a
  # value arriving back over progress messaging is validated, never rescaled.
  defp safe_retry_after_ms(ms) when is_integer(ms) and ms > 0, do: cap_retry_after_ms(ms)

  defp safe_retry_after_ms(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {ms, rest} ->
        if String.trim(rest) == "" and ms > 0, do: cap_retry_after_ms(ms), else: nil

      :error ->
        nil
    end
  end

  defp safe_retry_after_ms(_value), do: nil

  defp cap_retry_after_ms(ms), do: min(ms, @max_retry_after_ms)

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
