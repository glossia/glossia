defmodule Glossia.Foundation.Application.Web.Controllers.ErrorHTML do
  use Glossia.Foundation.Application.Web.Helpers.App, :html
  use Glossia.Features.Cloud.Marketing.Web.Helpers, :html

  # embed_templates "error_html/*"

  def get_seo_metadata(template, _assigns) do
    message = Phoenix.Controller.status_message_from_template(template)

    %{
      title: message,
      description:
        "Oops! It seems something went wrong. This page indicates an unexpected error occurred either on our server or on your client side. We apologize for the inconvenience and our team is working to resolve the issue. Please try again later or contact our support team if the problem persists."
    }
  end

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
