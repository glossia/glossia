defmodule Glossia.Stripe.Webhook do
  @moduledoc false

  import Plug.Crypto, only: [secure_compare: 2]

  @default_tolerance_sec 5 * 60

  def verify(headers, payload, secret, opts \\ [])
      when (is_list(headers) or is_map(headers)) and is_binary(payload) do
    with secret when is_binary(secret) and secret != "" <- secret || {:error, :missing_secret},
         signature_header when is_binary(signature_header) <- header(headers, "stripe-signature") ||
                                                            {:error, :missing_stripe_signature},
         {:ok, timestamp} <- extract_timestamp(signature_header),
         :ok <- validate_timestamp(timestamp, opts) do
      expected = expected_signature(secret, timestamp, payload)

      if valid_signature?(signature_header, expected) do
        :ok
      else
        {:error, :invalid_signature}
      end
    end
  end

  defp validate_timestamp(timestamp, opts) do
    tolerance = Keyword.get(opts, :tolerance_sec, @default_tolerance_sec)
    now = DateTime.utc_now() |> DateTime.to_unix()

    if abs(now - timestamp) <= tolerance do
      :ok
    else
      {:error, :timestamp_out_of_tolerance}
    end
  end

  defp extract_timestamp(signature_header) do
    signature_header
    |> String.split(",", trim: true)
    |> Enum.find_value(fn entry ->
      case String.split(entry, "=", parts: 2) do
        ["t", value] -> value
        _ -> nil
      end
    end)
    |> case do
      nil -> {:error, :missing_timestamp}
      value -> parse_int(value)
    end
  end

  defp expected_signature(secret, timestamp, payload) do
    message = "#{timestamp}.#{payload}"

    :crypto.mac(:hmac, :sha256, secret, message)
    |> Base.encode16(case: :lower)
  end

  defp valid_signature?(signature_header, expected) do
    signature_header
    |> String.split(",", trim: true)
    |> Enum.any?(fn entry ->
      case String.split(entry, "=", parts: 2) do
        ["v1", sig] when byte_size(sig) == byte_size(expected) ->
          secure_compare(sig, expected)

        ["v1", _sig] ->
          false

        _ ->
          false
      end
    end)
  end

  defp header(headers, name) when is_list(headers) do
    name = String.downcase(name)

    Enum.find_value(headers, fn
      {^name, value} -> value
      {key, value} when is_binary(key) -> if String.downcase(key) == name, do: value
      _ -> nil
    end)
  end

  defp header(headers, name) when is_map(headers) do
    Map.get(headers, name) || Map.get(headers, String.downcase(name)) || Map.get(headers, String.upcase(name))
  end

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end
end

