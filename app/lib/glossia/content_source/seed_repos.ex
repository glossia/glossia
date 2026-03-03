defmodule Glossia.ContentSource.SeedRepos do
  @moduledoc """
  Creates local git repositories with realistic content for development seeding.
  Called from `priv/repo/seeds.exs`.
  """

  require Logger

  @fixtures_base "fixtures/repos"

  @doc """
  Creates all local dev repos and returns a map of repo identifiers to their
  commit SHAs, e.g. `%{"dev-user/blog" => ["sha1", "sha2", ...]}`.
  """
  def create_all do
    base = Path.join(File.cwd!(), @fixtures_base)
    File.mkdir_p!(base)

    %{
      "dev-user/blog" => create_blog_repo(base),
      "acme-industries/docs" => create_docs_repo(base)
    }
  end

  defp create_blog_repo(base) do
    path = Path.join(base, "dev-user/blog")
    init_repo(path)

    commits = [
      {
        "Initial commit: add project structure",
        [
          {"README.md", "# My Blog\n\nA personal blog about software and languages.\n"},
          {"GLOSSIA.md",
           """
           content:
             source: content/posts
             pattern: "**/*.md"
           languages:
             source: en
             targets:
               - es
               - fr
           """}
        ]
      },
      {
        "feat: add first blog post about getting started",
        [
          {"content/posts/getting-started.md",
           """
           ---
           title: Getting Started with Glossia
           date: 2026-01-15
           ---

           Welcome to my blog! In this first post, I want to share how I got started
           with content localization and why it matters for reaching a global audience.

           ## Why localization matters

           When you publish content in a single language, you limit your reach. Over 75%
           of internet users prefer consuming content in their native language.

           ## Setting up Glossia

           Getting started is straightforward. Connect your repository and select your
           target languages. Glossia analyzes your content structure and generates
           translations that match your writing style.
           """}
        ]
      },
      {
        "feat: add blog post on translation workflows",
        [
          {"content/posts/translation-workflows.md",
           """
           ---
           title: Building Effective Translation Workflows
           date: 2026-02-01
           ---

           After a few weeks of using Glossia, I have developed a workflow that keeps
           my translations consistent and up to date.

           ## The review process

           Every translation goes through a review step. Glossia creates pull requests
           with the translated content so you can review changes before merging.

           ## Voice consistency

           One feature I find particularly useful is voice configuration. By defining
           a voice profile, every translation maintains the same tone and style.
           """}
        ]
      },
      {
        "fix: correct frontmatter date format in getting-started post",
        [
          {"content/posts/getting-started.md",
           """
           ---
           title: Getting Started with Glossia
           date: 2026-01-15T10:00:00Z
           author: dev
           ---

           Welcome to my blog! In this first post, I want to share how I got started
           with content localization and why it matters for reaching a global audience.

           ## Why localization matters

           When you publish content in a single language, you limit your reach. Over 75%
           of internet users prefer consuming content in their native language.

           ## Setting up Glossia

           Getting started is straightforward. Connect your repository and select your
           target languages. Glossia analyzes your content structure and generates
           translations that match your writing style.
           """}
        ]
      },
      {
        "feat: add Spanish translation for getting-started post",
        [
          {"content/posts/es/getting-started.md",
           """
           ---
           title: Primeros pasos con Glossia
           date: 2026-01-15T10:00:00Z
           author: dev
           language: es
           ---

           Bienvenido a mi blog. En esta primera entrada quiero compartir como empece
           con la localizacion de contenido y por que es importante para llegar a una
           audiencia global.

           ## Por que importa la localizacion

           Cuando publicas contenido en un solo idioma, limitas tu alcance. Mas del 75%
           de los usuarios de internet prefieren consumir contenido en su idioma nativo.
           """}
        ]
      },
      {
        "docs: update README with project overview",
        [
          {"README.md",
           """
           # My Blog

           A personal blog about software, languages, and content localization.

           ## Structure

           - `content/posts/` -- English source posts
           - `content/posts/es/` -- Spanish translations
           - `content/posts/fr/` -- French translations
           - `GLOSSIA.md` -- Glossia configuration

           ## Running locally

           ```
           npm run dev
           ```
           """}
        ]
      },
      {
        "feat: add blog post about voice configuration",
        [
          {"content/posts/voice-configuration.md",
           """
           ---
           title: Configuring Your Translation Voice
           date: 2026-02-20
           ---

           Your brand voice should be consistent across all languages. In this post,
           I cover how to set up voice profiles in Glossia.

           ## What is a voice profile?

           A voice profile defines the tone, formality level, and stylistic preferences
           for your translations. Think of it as a style guide that the translation
           engine follows.

           ## Creating a profile

           Navigate to the Voice section in your project settings. You can define
           attributes like formality (casual, neutral, formal), audience (technical,
           general), and specific terminology preferences.
           """}
        ]
      }
    ]

    create_commits(path, commits)
  end

  defp create_docs_repo(base) do
    path = Path.join(base, "acme-industries/docs")
    init_repo(path)

    commits = [
      {
        "Initial commit: project setup",
        [
          {"README.md", "# Acme Industries Documentation\n\nInternal product documentation.\n"},
          {"GLOSSIA.md",
           """
           content:
             source: docs
             pattern: "**/*.md"
           languages:
             source: en
             targets:
               - es
               - fr
               - de
           """}
        ]
      },
      {
        "feat: add API quickstart guide",
        [
          {"docs/quickstart.md",
           """
           ---
           title: API Quickstart
           ---

           # API Quickstart

           Get up and running with the Acme API in minutes.

           ## Authentication

           All API requests require a bearer token. Generate one in your dashboard
           under Settings > API Tokens.

           ## Making your first request

           ```bash
           curl -H "Authorization: Bearer YOUR_TOKEN" \\
             https://api.acme.example/v1/products
           ```
           """}
        ]
      },
      {
        "feat: add product catalog documentation",
        [
          {"docs/products/overview.md",
           """
           ---
           title: Product Catalog
           ---

           # Product Catalog

           The product catalog API lets you manage your product listings
           programmatically.

           ## Endpoints

           - `GET /v1/products` -- List all products
           - `GET /v1/products/:id` -- Get a single product
           - `POST /v1/products` -- Create a product
           - `PATCH /v1/products/:id` -- Update a product
           - `DELETE /v1/products/:id` -- Delete a product
           """}
        ]
      },
      {
        "fix: correct authentication header example",
        [
          {"docs/quickstart.md",
           """
           ---
           title: API Quickstart
           ---

           # API Quickstart

           Get up and running with the Acme API in minutes.

           ## Authentication

           All API requests require a bearer token. Generate one in your dashboard
           under Settings > API Tokens.

           ## Making your first request

           ```bash
           curl -H "Authorization: Bearer $ACME_TOKEN" \\
             https://api.acme.example/v1/products
           ```

           ## Rate limits

           The API allows 300 read requests and 60 write requests per minute.
           """}
        ]
      },
      {
        "feat: add webhook documentation",
        [
          {"docs/webhooks.md",
           """
           ---
           title: Webhooks
           ---

           # Webhooks

           Receive real-time notifications when events occur in your account.

           ## Supported events

           - `product.created`
           - `product.updated`
           - `order.placed`
           - `order.shipped`

           ## Verifying signatures

           Each webhook request includes an `X-Acme-Signature` header. Verify it
           using HMAC-SHA256 with your webhook secret.
           """}
        ]
      }
    ]

    create_commits(path, commits)
  end

  defp init_repo(path) do
    if File.dir?(path) do
      File.rm_rf!(path)
    end

    File.mkdir_p!(path)

    git!(path, ["init", "--initial-branch=main"])
    git!(path, ["config", "user.email", "dev@glossia.ai"])
    git!(path, ["config", "user.name", "Dev User"])
  end

  defp create_commits(path, commits) do
    now = DateTime.utc_now()
    total = length(commits)

    commits
    |> Enum.with_index()
    |> Enum.map(fn {{message, files}, index} ->
      # Space commits out, oldest first
      offset_seconds = (total - 1 - index) * -3600 * 24
      date = DateTime.add(now, offset_seconds, :second)
      date_string = DateTime.to_iso8601(date)

      Enum.each(files, fn {file_path, content} ->
        full_path = Path.join(path, file_path)
        File.mkdir_p!(Path.dirname(full_path))
        File.write!(full_path, content)
      end)

      git!(path, ["add", "."])

      git!(path, ["commit", "-m", message, "--date=#{date_string}"],
        env: [{"GIT_COMMITTER_DATE", date_string}]
      )

      {output, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: path)
      String.trim(output)
    end)
  end

  defp git!(path, args, opts \\ []) do
    sys_opts = [cd: path, stderr_to_stdout: true]

    sys_opts =
      case Keyword.get(opts, :env) do
        nil -> sys_opts
        env -> Keyword.put(sys_opts, :env, env)
      end

    case System.cmd("git", args, sys_opts) do
      {_output, 0} ->
        :ok

      {output, code} ->
        raise "git #{Enum.join(args, " ")} failed (exit #{code}) in #{path}: #{output}"
    end
  end
end
