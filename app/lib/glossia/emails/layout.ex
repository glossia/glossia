defmodule Glossia.Emails.Layout do
  @moduledoc """
  Shared email layout adapted from Tuist's account notifier.

  Email clients need inline styles and resolved colors. These semantic
  values mirror Glossia's warm stone and violet theme in styles.css.
  """

  use GlossiaWeb, :verified_routes

  require EEx

  @theme %{
    background: "#faf8f5",
    surface: "#ffffff",
    text: "#1c1917",
    muted: "#5c564e",
    primary: "#6d3cc4",
    border: "#e4e0d9",
    on_primary: "#ffffff",
    spacing: %{small: 8, medium: 16, large: 24, xlarge: 32, logo: 48},
    radius: 8,
    font_body: 16,
    font_heading: 32,
    font_footer: 12
  }

  def render(assigns) do
    assigns
    |> Map.put(:theme, @theme)
    |> Map.put(:logo_url, marketing_url(~p"/images/logo-rounded.png"))
    |> Map.put(:home_url, marketing_url(~p"/"))
    |> Map.put(:privacy_url, marketing_url(~p"/privacy"))
    |> render_template()
  end

  EEx.function_from_file(:defp, :render_template, Path.expand("layout.html.eex", __DIR__), [
    :assigns
  ])

  defp escape(value), do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp marketing_url(path), do: "https://glossia.ai" |> URI.merge(path) |> URI.to_string()
end
