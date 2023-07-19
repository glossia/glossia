defmodule GlossiaWeb.ErrorHTML do
  use GlossiaWeb, :app_html
  use GlossiaWeb, :marketing_html

  # embed_templates "error_html/*"

  def get_seo_metadata(template, _) do
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
  def render(template, assigns) do
    message = Phoenix.Controller.status_message_from_template(template)
    ~H"""
    <section >
      <div class="items-center flex h-screen justify-center">
        <section>
          <div class="2xl:max-w-7xl mx-auto">
            <div class="text-center">
              <h1
                class="text-4xl sm:text-6xl mx-auto font-bold text-black tracking-widest md:tracking-normal uppercase md:text-7xl lg:text-9xl xl:text-13xl">
                <%= message %>
              </h1>
              <div class="flex-col flex gap-3 mt-10 sm:flex-row justify-center">
                <a
                  class="text-black items-center shadow-[5px_5px_black] inline-flex px-6 focus:outline-none justify-center text-center bg-white border-black ease-in-out hover:text-white transform transition hover:shadow-none border-2 duration-200 hover:bg-black lg:w-auto py-3 rounded-xl w-full"
                  href={~p"/"}
                  >Go back home <span class="ml-3">&rarr;</span></a>
              </div>
            </div>
          </div>
        </section>
      </div>
    </section>
    """
  end
end
