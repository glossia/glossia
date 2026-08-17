defmodule Glossia.Quality.URLSafety do
  @moduledoc false

  def validate_origins(origins) when is_map(origins) do
    case browser_policy(origins) do
      {:ok, _policy} -> :ok
      {:error, _reason} = error -> error
    end
  end

  def validate_origins(_origins), do: {:error, :invalid_locale_origins}

  def validate_origin(origin) when is_binary(origin) do
    case browser_policy(%{"origin" => origin}) do
      {:ok, _policy} -> :ok
      {:error, _reason} = error -> error
    end
  end

  def validate_origin(_origin), do: {:error, :invalid_origin}

  def browser_policy(origins) when is_map(origins) do
    origins
    |> Map.values()
    |> Enum.uniq()
    |> Enum.reduce_while({:ok, %{}}, fn origin, {:ok, pinned_hosts} ->
      case validate_and_resolve_origin(origin) do
        {:ok, host, address} -> {:cont, {:ok, Map.put(pinned_hosts, host, address)}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, pinned_hosts} when map_size(pinned_hosts) > 0 ->
        {:ok,
         %{
           pinned_hosts: pinned_hosts,
           resolver_rules: resolver_rules(pinned_hosts)
         }}

      {:ok, _pinned_hosts} ->
        {:error, :invalid_locale_origins}

      {:error, _reason} = error ->
        error
    end
  end

  def browser_policy(_origins), do: {:error, :invalid_locale_origins}

  defp validate_and_resolve_origin(origin) do
    case URI.parse(origin) do
      %URI{scheme: scheme, host: host, userinfo: nil, query: nil, fragment: nil}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        with {:ok, addresses} <- resolve_addresses(host),
             :ok <- validate_addresses(host, addresses) do
          {:ok, String.downcase(host), pinned_address(addresses)}
        end

      _other ->
        {:error, :invalid_origin}
    end
  end

  defp validate_addresses(host, addresses) do
    if allow_private_origins?() do
      :ok
    else
      normalized = String.downcase(host)

      cond do
        normalized in ["localhost", "localhost.localdomain"] ->
          {:error, :private_origin_not_allowed}

        Enum.any?(addresses, &private_address?/1) ->
          {:error, :private_origin_not_allowed}

        true ->
          :ok
      end
    end
  end

  defp pinned_address(addresses) do
    address = Enum.find(addresses, &(tuple_size(&1) == 4)) || List.first(addresses)
    address = address |> :inet.ntoa() |> List.to_string()

    if String.contains?(address, ":"), do: "[#{address}]", else: address
  end

  defp resolver_rules(pinned_hosts) do
    mappings =
      pinned_hosts
      |> Enum.sort_by(fn {host, _address} -> host end)
      |> Enum.map_join(",", fn {host, address} -> "MAP #{resolver_host(host)} #{address}" end)

    mappings <> ",MAP * ~NOTFOUND"
  end

  defp resolver_host(host) do
    if String.contains?(host, ":"), do: "[#{host}]", else: host
  end

  defp resolve_addresses(host) do
    host = String.to_charlist(host)

    addresses =
      [:inet, :inet6]
      |> Enum.flat_map(fn family ->
        case :inet.getaddrs(host, family) do
          {:ok, values} -> values
          {:error, _reason} -> []
        end
      end)
      |> Enum.uniq()

    if addresses == [], do: {:error, :origin_not_resolvable}, else: {:ok, addresses}
  end

  defp private_address?({10, _, _, _}), do: true
  defp private_address?({100, second, _, _}) when second in 64..127, do: true
  defp private_address?({127, _, _, _}), do: true
  defp private_address?({169, 254, _, _}), do: true
  defp private_address?({172, second, _, _}) when second in 16..31, do: true
  defp private_address?({192, 0, 0, _}), do: true
  defp private_address?({192, 0, 2, _}), do: true
  defp private_address?({192, 168, _, _}), do: true
  defp private_address?({198, second, _, _}) when second in 18..19, do: true
  defp private_address?({198, 51, 100, _}), do: true
  defp private_address?({203, 0, 113, _}), do: true
  defp private_address?({first, _, _, _}) when first >= 224, do: true
  defp private_address?({0, _, _, _}), do: true
  defp private_address?({255, 255, 255, 255}), do: true
  defp private_address?({0, 0, 0, 0, 0, 0, 0, 0}), do: true
  defp private_address?({0, 0, 0, 0, 0, 0, 0, 1}), do: true

  defp private_address?({0, 0, 0, 0, 0, 0xFFFF, high, low}) do
    private_address?({div(high, 256), rem(high, 256), div(low, 256), rem(low, 256)})
  end

  defp private_address?({first, _, _, _, _, _, _, _}) when first in 0xFC00..0xFDFF, do: true
  defp private_address?({first, _, _, _, _, _, _, _}) when first in 0xFE80..0xFEBF, do: true
  defp private_address?({first, _, _, _, _, _, _, _}) when first in 0xFF00..0xFFFF, do: true
  defp private_address?(_address), do: false

  defp allow_private_origins? do
    :glossia
    |> Application.get_env(Glossia.Quality, [])
    |> Keyword.get(:allow_private_origins, false)
  end
end
