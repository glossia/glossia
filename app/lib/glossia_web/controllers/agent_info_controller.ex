defmodule GlossiaWeb.AgentInfoController do
  use GlossiaWeb, :controller

  alias Glossia.{Blog, Docs, Features, I18n}

  def show(conn, _params) do
    base_url = GlossiaWeb.Endpoint.url()
    locale = I18n.default_locale()

    content =
      [
        "# Glossia",
        "",
        "> Glossia is a language platform for teams that need consistent content across languages and surfaces.",
        "",
        "## Product",
        link(base_url, ~p"/features", "Features", "Explore the language platform."),
        link(
          base_url,
          ~p"/blog",
          "Blog",
          "Notes on localization, language systems, and agentic workflows."
        ),
        "",
        "## Documentation",
        Enum.map(Docs.all_pages(locale), &documentation_link(base_url, &1)),
        "",
        "## Feature guides",
        Enum.map(Features.all_pages(locale), &feature_link(base_url, &1)),
        "",
        "## Recent writing",
        Enum.map(Blog.recent_posts(10, locale), &blog_link(base_url, &1))
      ]
      |> List.flatten()
      |> Enum.join("\n")
      |> Kernel.<>("\n")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, content)
  end

  defp documentation_link(base_url, page) do
    link(base_url, Docs.path_for(page), page.title, page.summary)
  end

  defp feature_link(base_url, page) do
    link(base_url, ~p"/features/#{page.slug}", page.title, page.summary)
  end

  defp blog_link(base_url, post) do
    link(base_url, ~p"/blog/#{post.slug}", post.title, post.summary)
  end

  defp link(base_url, path, title, summary) do
    url = base_url |> URI.merge(path) |> URI.to_string()
    "- [#{title}](#{url}): #{summary}"
  end
end
