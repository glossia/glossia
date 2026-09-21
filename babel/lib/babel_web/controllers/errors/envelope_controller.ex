defmodule BabelWeb.Errors.EnvelopeController do
  @moduledoc """
  Sentry-compatible envelope ingestion. Accepts POSTs at
  `POST /api/:project_id/envelope/` — the URL shape every official
  Sentry SDK writes to given a `dsn` of
  `https://<public_key>@<host>/<project_id>`.

  The endpoint is public but DSN-authenticated: the `sentry_key` in
  the `X-Sentry-Auth` header (or `?sentry_key=` query param) has to
  resolve to a `Babel.Errors.Key` whose `dsn_project_id` matches the
  URL segment. On failure we return `401` with `{"detail":"invalid_dsn"}`
  and never disclose whether the key or the project id was the
  problem. On success we hand the raw body to
  `Babel.Errors.ingest_envelope/2` and respond `200` with the event id
  — Sentry's SDK contract.

  We deliberately never return 5xx after DSN validation: Sentry SDKs
  cache and retry on server errors, and a stuck malformed envelope
  would loop forever. The context module swallows parse errors and
  logs a warning; anything reaching this controller as `{:error, _}`
  gets 400 instead so a bad SDK is loud but not retried.
  """

  use BabelWeb, :controller

  require Logger

  alias Babel.Errors
  alias Babel.Errors.Envelope
  alias Babel.Errors.Key

  @max_body_bytes 20 * 1024 * 1024
  @allowed_headers "authorization, content-type, sentry-trace, baggage, x-sentry-auth"

  def ingest(conn, %{"project_id" => project_id}) do
    with {:ok, body, conn} <- read_full_body(conn),
         {:ok, body} <- decode_body(body, content_encoding(conn)),
         {:ok, public_key} <- extract_public_key(conn),
         {:ok, %Key{} = key} <- Errors.find_key_by_public(public_key),
         :ok <- verify_project(key, project_id) do
      :ok = Errors.ingest_envelope(key.organization_id, body)
      Errors.touch_key(key)

      conn
      |> put_cors_headers()
      |> put_status(:ok)
      |> json(%{id: extract_event_id(body)})
    else
      {:error, :body_too_large} ->
        send_json(conn, 413, %{detail: "body_too_large"})

      {:error, :unsupported_encoding} ->
        send_json(conn, 415, %{detail: "unsupported_encoding"})

      {:error, :invalid_encoding} ->
        send_json(conn, 400, %{detail: "invalid_encoding"})

      {:error, :missing_key} ->
        send_json(conn, 401, %{detail: "invalid_dsn"})

      {:error, :not_found} ->
        send_json(conn, 401, %{detail: "invalid_dsn"})

      {:error, :project_mismatch} ->
        send_json(conn, 401, %{detail: "invalid_dsn"})

      {:error, reason} ->
        Logger.warning("errors: ingest failed: #{inspect(reason)}")
        send_json(conn, 400, %{detail: to_string_reason(reason)})
    end
  end

  # CORS preflight: browser SDK sends OPTIONS before the POST.
  def options(conn, _params) do
    conn
    |> put_cors_headers()
    |> send_resp(200, "")
  end

  ## body handling

  defp read_full_body(conn) do
    case conn.private[:babel_raw_body] do
      body when is_binary(body) and byte_size(body) > @max_body_bytes ->
        {:error, :body_too_large}

      body when is_binary(body) ->
        {:ok, body, conn}

      _ ->
        do_read_body(conn, [], 0)
    end
  end

  # Fallback for requests where the caching body reader did not fire —
  # e.g. content-type routed the body straight past `Plug.Parsers`.
  defp do_read_body(_conn, _acc, size) when size > @max_body_bytes,
    do: {:error, :body_too_large}

  defp do_read_body(conn, acc, size) do
    case Plug.Conn.read_body(conn, length: 1_000_000) do
      {:ok, chunk, conn} ->
        {:ok, IO.iodata_to_binary(Enum.reverse([chunk | acc])), conn}

      {:more, chunk, conn} ->
        do_read_body(conn, [chunk | acc], size + byte_size(chunk))

      {:error, _} = err ->
        err
    end
  end

  defp content_encoding(conn) do
    conn
    |> Plug.Conn.get_req_header("content-encoding")
    |> List.first()
    |> case do
      nil -> nil
      value -> value |> String.downcase() |> String.trim()
    end
  end

  defp decode_body(body, encoding) when encoding in [nil, "", "identity"], do: {:ok, body}
  defp decode_body(body, "gzip"), do: bounded_inflate(body, 31)
  defp decode_body(body, "deflate"), do: bounded_inflate(body, 15)
  defp decode_body(_body, _other), do: {:error, :unsupported_encoding}

  # Bounded inflate: guard against a small compressed payload that
  # decompresses into gigabytes. Feed the stream in 64 KiB chunks and
  # abort as soon as the decoded size crosses `@max_body_bytes`.
  defp bounded_inflate(body, window_bits) do
    z = :zlib.open()

    try do
      :zlib.inflateInit(z, window_bits)
      inflate_stream(z, body, [], 0)
    rescue
      _ -> {:error, :invalid_encoding}
    after
      _ = safe_inflate_end(z)
      :zlib.close(z)
    end
  end

  @inflate_chunk 65_536

  defp inflate_stream(_z, _rest, _acc, size) when size > @max_body_bytes,
    do: {:error, :body_too_large}

  defp inflate_stream(_z, <<>>, acc, _size) do
    {:ok, acc |> Enum.reverse() |> IO.iodata_to_binary()}
  end

  defp inflate_stream(z, rest, acc, size) do
    {chunk, tail} = take_chunk(rest)
    output = :zlib.inflate(z, chunk)
    output_bytes = IO.iodata_length(output)
    inflate_stream(z, tail, [output | acc], size + output_bytes)
  end

  defp take_chunk(binary) when byte_size(binary) <= @inflate_chunk,
    do: {binary, <<>>}

  defp take_chunk(binary) do
    <<head::binary-size(@inflate_chunk), tail::binary>> = binary
    {head, tail}
  end

  defp safe_inflate_end(z) do
    :zlib.inflateEnd(z)
  rescue
    _ -> :ok
  end

  ## auth

  defp extract_public_key(conn) do
    with :missing <- header_key(conn),
         :missing <- query_key(conn) do
      {:error, :missing_key}
    else
      {:ok, key} -> {:ok, key}
    end
  end

  defp header_key(conn) do
    case Plug.Conn.get_req_header(conn, "x-sentry-auth") do
      [value | _] ->
        case parse_sentry_auth(value) do
          {:ok, key} -> {:ok, key}
          :error -> :missing
        end

      _ ->
        :missing
    end
  end

  defp query_key(conn) do
    case conn.query_params do
      %Plug.Conn.Unfetched{} ->
        conn = Plug.Conn.fetch_query_params(conn)
        do_query_key(conn.query_params)

      params ->
        do_query_key(params)
    end
  end

  defp do_query_key(%{"sentry_key" => key}) when is_binary(key) and key != "", do: {:ok, key}
  defp do_query_key(_), do: :missing

  # `X-Sentry-Auth: Sentry sentry_version=7, sentry_key=<pk>, sentry_client=...`
  defp parse_sentry_auth(value) when is_binary(value) do
    value
    |> String.replace_prefix("Sentry ", "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn pair ->
      case String.split(pair, "=", parts: 2) do
        [k, v] -> {String.trim(k), String.trim(v, "\"") |> String.trim()}
        _ -> {"", ""}
      end
    end)
    |> Enum.into(%{})
    |> case do
      %{"sentry_key" => key} when is_binary(key) and key != "" -> {:ok, key}
      _ -> :error
    end
  end

  defp verify_project(%Key{dsn_project_id: id}, project_id) do
    if to_string(id) == to_string(project_id),
      do: :ok,
      else: {:error, :project_mismatch}
  end

  ## response helpers

  defp put_cors_headers(conn) do
    conn
    |> Plug.Conn.put_resp_header("access-control-allow-origin", "*")
    |> Plug.Conn.put_resp_header("access-control-allow-methods", "POST, OPTIONS")
    |> Plug.Conn.put_resp_header("access-control-allow-headers", @allowed_headers)
    |> Plug.Conn.put_resp_header("access-control-max-age", "86400")
  end

  defp send_json(conn, status, body) do
    conn
    |> put_cors_headers()
    |> put_resp_content_type("application/json")
    |> send_resp(status, JSON.encode!(body))
  end

  defp to_string_reason(reason) when is_binary(reason), do: reason
  defp to_string_reason(reason), do: inspect(reason)

  ## event id extraction (best-effort — used only for the response body)

  defp extract_event_id(body) do
    case Envelope.parse(body) do
      {:ok, %{header: %{"event_id" => id}}} when is_binary(id) ->
        normalize_event_id(id)

      {:ok, %{items: items}} ->
        find_event_id_in_items(items) || random_event_id()

      _ ->
        random_event_id()
    end
  end

  defp find_event_id_in_items(items) do
    Enum.find_value(items, &event_id_from_item/1)
  end

  defp event_id_from_item(%{type: "event", payload: payload}) do
    case JSON.decode(payload) do
      {:ok, %{"event_id" => id}} when is_binary(id) -> normalize_event_id(id)
      _ -> nil
    end
  end

  defp event_id_from_item(_), do: nil

  defp normalize_event_id(id), do: String.replace(id, "-", "") |> String.downcase()

  defp random_event_id do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
