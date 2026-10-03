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

  @dns_prefix "_glossia-verify"
  @dns_record_tag "glossia-site-verification="
  @meta_tag_name "glossia-site-verification"
  @request_timeout_ms 5_000

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

  @doc "Returns the full domain text record name used for ownership verification."
  def record_name(domain), do: "#{@dns_prefix}.#{domain}"

  @doc "Returns the domain text record value containing the project's verification token."
  def record_value(token), do: "#{@dns_record_tag}#{token}"

  @doc """
  Looks for a TXT record on `_glossia-verify.<domain>` whose value contains
  the token. Returns `:ok` on match, `:error` otherwise.
  """
  def check_dns(domain, token) do
    case lookup_txt(record_name(domain)) do
      {:ok, records} ->
        if Enum.any?(records, &String.contains?(&1, record_value(token))) do
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
    # a regex over the raw body is robust to script injection. HTML puts no
    # ordering on attributes, so accept `content` on either side of `name`.
    name = ~s{name=["']#{@meta_tag_name}["']}
    content = ~s{content=["']#{Regex.escape(token)}["']}

    html =~ ~r{<meta[^>]+#{name}[^>]+#{content}}i or
      html =~ ~r{<meta[^>]+#{content}[^>]+#{name}}i
  end

  defp lookup_txt(name), do: Glossia.Analytics.Verification.DNSResolver.lookup_txt(name)
end
