defmodule GlossiaWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use GlossiaWeb, :html

  embed_templates "error_html/*"

  # Fallback for templates that don't have a matching .html.heex file: render
  # the plain-text status message so a browser still gets *something*.
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
