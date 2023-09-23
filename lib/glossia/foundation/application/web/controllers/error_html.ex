defmodule Glossia.Foundation.Application.Web.Controllers.ErrorHTML do
  # use Glossia.Foundation.Application.Web.Helpers.App, :html

  # embed_templates "error_html/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
