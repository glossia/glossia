defmodule Glossia.Gitlab.Webhook do
  @moduledoc false

  import Plug.Crypto, only: [secure_compare: 2]

  @doc """
  Verifies a GitLab webhook secret token.

  GitLab sends a `x-gitlab-token` header containing the shared secret token
  configured when creating the webhook. Verification is a constant-time
  string comparison.
  """
  def verify(headers, _payload, secret) do
    with secret when is_binary(secret) and secret != "" <-
           if(is_binary(secret) and secret != "", do: secret, else: {:error, :missing_secret}),
         token when is_binary(token) <-
           header(headers, "x-gitlab-token") || {:error, :missing_token} do
      if secure_compare(token, secret) do
        :ok
      else
        {:error, :invalid_token}
      end
    end
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
