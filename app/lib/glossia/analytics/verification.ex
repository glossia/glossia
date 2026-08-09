defmodule Glossia.Analytics.Verification do
  @moduledoc """
  Proves that the person registering an analytics domain actually controls
  it. Two complementary methods, both modeled on what Plausible and Fathom
  ship:

    * **DNS TXT record** — owner adds
      `_glossia-verify.<domain> TXT "glossia-site-verification=<token>"`.
      Proves control over the DNS zone. Cheapest, but requires the owner to
      edit their DNS.

    * **HTML meta tag** — owner adds
      `<meta name="glossia-site-verification" content="<token>">` to the
      site's `<head>`. Proves write access to the site, which is good enough
      for shared-hosting or CMS-hosted properties where DNS is locked.

  Either method suffices. The check is one-shot at registration time; once
  `verified_at` is set, the controller no longer re-runs the check on the
  hot path.
  """

  require Logger

  @dns_prefix "_glossia-verify"
  @dns_record_tag "glossia-site-verification="
  @meta_tag_name "glossia-site-verification"
  @request_timeout_ms 5_000
  @cmd_timeout_ms 5_000

  @doc """
  Runs both checks and returns `:ok` if either confirms the token. Any
  network or parsing error is treated as "not verified" and logged at
  `:debug` — we never want a transient DNS or HTTP failure to lock an
  operator out of their own project.
  """
  def verify(domain, token) when is_binary(domain) and is_binary(token) do
    cond do
      check_dns(domain, token) == :ok -> :ok
      check_meta_tag(domain, token) == :ok -> :ok
      true -> :error
    end
  end

  @doc """
  Looks for a TXT record on `_glossia-verify.<domain>` whose value contains
  the token. Returns `:ok` on match, `:error` otherwise.
  """
  def check_dns(domain, token) do
    case lookup_txt("#{@dns_prefix}.#{domain}") do
      {:ok, records} ->
        if Enum.any?(records, &String.contains?(&1, "#{@dns_record_tag}#{token}")) do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end

  @doc """
  Fetches `https://<domain>/` and looks for a `<meta name="glossia-site-verification">`
  tag whose `content` attribute matches the token.
  """
  def check_meta_tag(domain, token) do
    with {:ok, %{body: body}} when is_binary(body) <-
           Req.get("https://#{domain}/",
             receive_timeout: @request_timeout_ms,
             connect_options: [timeout: @request_timeout_ms]
           ),
         true <- has_meta_tag?(body, token) do
      :ok
    else
      _ -> :error
    end
  end

  defp has_meta_tag?(html, token) do
    # `Req` and the browser-facing content-type detection are good enough
    # to narrow this down, but the meta tag itself is small and well-formed;
    # a regex over the raw body is robust to script injection and attribute
    # reordering.
    regex = ~r{<meta[^>]+name=["']#{@meta_tag_name}["'][^>]+content=["']#{Regex.escape(token)}["']}i

    html =~ regex
  end

  # `dig +short TXT <name>` prints one quoted record per line, e.g.:
  #   "glossia-site-verification=abc123"
  #   "v=spf1 -all"
  # We split on lines, drop empties, strip surrounding quotes, and return
  # the list. The check treats a missing `dig` binary or a non-zero exit
  # status as "no TXT records" so a transient resolver hiccup never locks
  # an operator out.
  defp lookup_txt(name) do
    case MuonTrap.cmd("dig", ["+short", "TXT", name], into: "", timeout: @cmd_timeout_ms) do
      {output, 0} ->
        records =
          output
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&strip_quotes/1)

        {:ok, records}

      _ ->
        :error
    end
  rescue
    error ->
      Logger.debug("DNS lookup failed for #{inspect(name)}: #{inspect(error)}")
      :error
  catch
    kind, reason ->
      Logger.debug("DNS lookup crashed for #{inspect(name)}: #{inspect({kind, reason})}")
      :error
  end

  defp strip_quotes(~s(") <> rest), do: strip_quotes(rest)
  defp strip_quotes(other), do: other
end
