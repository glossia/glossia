defmodule GlossiaWeb.AgentInfoController do
  use GlossiaWeb, :controller

  alias Glossia.{Blog, Docs, Features, I18n, PublicContent}
  alias GlossiaWeb.MarkdownResponse

  def show(conn, _params) do
    base_url = GlossiaWeb.Endpoint.url()
    locale = I18n.default_locale()

    content =
      [
        "# Glossia",
        "",
        "> Glossia is a language OS for teams that need consistent content across languages and surfaces.",
        "",
        "Glossia combines shared voice and terminology, Git-based localization, validation, revision history, and localization analytics. Repository-owned content and pull-request review align language work with continuous delivery instead of making a proprietary editing workspace the authority. Glossia supplies the context and review workflow around AI-generated drafts rather than replacing editorial judgment.",
        "",
        "Published content supports Accept: text/markdown and explicit .md URLs. Locale-prefixed URLs serve the requested language with English fallback. Account dashboards are not documentation and should not be crawled.",
        "",
        link(
          base_url,
          ~p"/llms-full.txt",
          "Full documentation",
          "A consolidated Markdown export of the documentation."
        ),
        "",
        "## Product",
        link(
          base_url,
          ~p"/index.md",
          "Glossia",
          "The problems Glossia solves and its role in your workflow."
        ),
        link(base_url, ~p"/features.md", "Features", "Explore the language OS."),
        link(
          base_url,
          ~p"/blog.md",
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
        Enum.map(Blog.recent_posts(10, locale), &blog_link(base_url, &1)),
        link(base_url, ~p"/changelog.md", "Changelog", "Published product changes."),
        "",
        "## Policies",
        link(base_url, ~p"/terms.md", "Terms", "Hosted-service terms."),
        link(base_url, ~p"/privacy.md", "Privacy", "Hosted-service privacy policy."),
        link(base_url, ~p"/cookies.md", "Cookies", "Hosted-service cookie policy.")
      ]
      |> List.flatten()
      |> Enum.join("\n")
      |> Kernel.<>("\n")

    MarkdownResponse.send(conn, content, content_type: "text/plain", robots: "noindex, follow")
  end

  def full(conn, _params) do
    pages = PublicContent.documents()

    content =
      [
        "# Glossia documentation\n",
        Map.fetch!(pages, ~p"/")
        | Enum.map(Docs.all_pages(), fn page ->
            path = Docs.path_for(page)
            source = GlossiaWeb.Endpoint.url() |> URI.merge(path) |> URI.to_string()
            "Source: #{source}\n\n#{Map.fetch!(pages, path)}"
          end)
      ]
      |> Enum.join("\n\n---\n\n")

    MarkdownResponse.send(conn, content, content_type: "text/plain", robots: "noindex, follow")
  end

  defp documentation_link(base_url, page) do
    link(base_url, PublicContent.markdown_path(Docs.path_for(page)), page.title, page.summary)
  end

  defp feature_link(base_url, page) do
    link(base_url, ~p"/features/#{page.slug <> ".md"}", page.title, page.summary)
  end

  defp blog_link(base_url, post) do
    link(base_url, ~p"/blog/#{post.slug <> ".md"}", post.title, post.summary)
  end

  defp link(base_url, path, title, summary) do
    url = base_url |> URI.merge(path) |> URI.to_string()
    "- [#{title}](#{url}): #{summary}"
  end
end
