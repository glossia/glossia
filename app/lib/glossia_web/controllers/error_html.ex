defmodule GlossiaWeb.ErrorHTML do
  @moduledoc """
  Self-contained HTML error pages that do not depend on a session or application layout.
  """
  use GlossiaWeb, :html

  embed_templates "error_html/*"

  def render(template, assigns) do
    {title, message} =
      case template do
        "404.html" ->
          {gettext("This page got lost in translation"),
           gettext("The page you're looking for doesn't exist or may have moved.")}

        "429.html" ->
          {gettext("Slow down for a moment"),
           gettext(
             "This page has received a lot of requests in a short time from your network. Try again in %{seconds} seconds.",
             seconds: assigns[:retry_after] || 60
           )}

        "500.html" ->
          {gettext("Something went wrong on our side"),
           gettext("Please try again in a moment. If the problem continues, contact us for help.")}

        _ ->
          {Phoenix.Controller.status_message_from_template(template),
           gettext(
             "We couldn't complete this request. Please check the address or try again later."
           )}
      end

    assigns
    |> Map.put(:status, Path.rootname(template))
    |> Map.put(:title, title)
    |> Map.put(:message, message)
    |> error()
  end
end
