defmodule GlossiaWeb.WebAnalytics do
  @moduledoc """
  Renders the Glossia web analytics snippet when dogfooding is enabled.

  Gated on a configured `domain` (see `:glossia, :web_analytics`), so the snippet
  is a no-op until a site domain is provided. The script is bundled from the same
  `sdk/web` source via the `glossia_sdk_web` esbuild profile.
  """

  @doc """
  Returns `{:safe, iodata}` for the analytics `<script>` tag, or an empty safe
  string when dogfooding is disabled.
  """
  def snippet do
    case Application.get_env(:glossia, :web_analytics, [])[:domain] do
      nil ->
        {:safe, ""}

      domain ->
        escaped = domain |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        {:safe, ~s(<script defer src="/assets/glossia-web.js" data-domain="#{escaped}"></script>)}
    end
  end
end
