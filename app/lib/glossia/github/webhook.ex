defmodule Glossia.Github.Webhook do
  @moduledoc false

  import Plug.Crypto, only: [secure_compare: 2]

  @doc """
  Verifies a GitHub webhook signature.

  GitHub sends a `x-hub-signature-256` header containing `sha256=<hex_digest>`.
  The digest is computed as HMAC-SHA256 of the raw request body using the
  webhook secret as the key.
  """
  def verify(headers, payload, secret) when is_binary(payload) do
    with secret when is_binary(secret) and secret != "" <-
           if(is_binary(secret) and secret != "", do: secret, else: {:error, :missing_secret}),
         signature when is_binary(signature) <-
           header(headers, "x-hub-signature-256") || {:error, :missing_signature} do
      expected = expected_signature(secret, payload)

      if secure_compare("sha256=#{expected}", signature) do
        :ok
      else
        {:error, :invalid_signature}
      end
    end
  end

  defp expected_signature(secret, payload) do
    :crypto.mac(:hmac, :sha256, secret, payload)
    |> Base.encode16(case: :lower)
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
    Map.get(headers, name) || Map.get(headers, String.downcase(name))
  end
end
