%{
  title: "Public content and crawler interfaces",
  summary: "HTML, Markdown, discovery, caching, and crawler boundaries for the public website.",
  category: "reference",
  section: "platform",
  order: 10
}
---

Glossia exposes published website content separately from account and project application surfaces.

## Representations

| Interface | Behavior |
|---|---|
| A published HTML URL | The browser representation, with canonical metadata and a Markdown alternate `Link` response header. |
| `Accept: text/markdown` at that URL | A Markdown representation when the explicit media type has positive quality and is not less preferred than `text/html`. |
| The page URL with `.md` appended | An explicit Markdown representation, independent of browser language preference. |
| `/index.md` | The homepage's Markdown overview. |
| `/docs.md`, `/blog.md`, `/features.md` | Markdown indexes of published content. |
| `/changelog.md` | Published changelog entries in one Markdown document. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | The latest published legal documents. Dated legal URLs also support `.md`. |

`*/*` alone does not opt into Markdown. HTML responses and Markdown responses share `Vary: Accept` so caches do not mix the representations.

Individual documentation, blog, feature, and legal content uses authored Markdown rather than a conversion of the rendered HTML. Index pages are generated from the published inventory; the homepage has a curated Markdown overview. The interactive REST reference points readers to the OpenAPI specification rather than embedding a browser-only API widget.

## Locales

English is unprefixed. Translated marketing URLs use literal prefixes: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br`, and `/zh-hans`. For example, `/es/docs/tutorials/getting-started.md` serves the Spanish version when it is published.

The URL chooses the Markdown content's language. `Accept-Language` does not redirect a Markdown request. A missing content translation falls back to its English source. The homepage overview is currently authored in English.

## Discovery

- `/robots.txt` defaults to disallowing crawling and opts in the finite published HTML and Markdown inventory, localized feeds, rendering assets under `/assets/`, `/fonts/`, and `/images/`, the favicon, and public marketing previews under `/og/marketing/`. Account preview images under `/og/app/` remain disallowed. It is guidance for cooperative crawlers, not an authorization mechanism.
- `/sitemap.xml` lists canonical public HTML content with locale alternates. Changelog fragments are not separate URLs.
- `/llms.txt` introduces Glossia and links to public documentation, feature guides, and recent writing, including explicit Markdown links.
- `/llms-full.txt` exports the homepage overview and complete documentation inventory in one text document containing Markdown.

Authentication, account dashboards, APIs, and other application responses are marked `noindex, nofollow`. Published successful content is marked `index, follow`; errors remain nonindexable. Discovery text files (`/robots.txt`, `/llms.txt`, and `/llms-full.txt`) use `noindex, follow`: readers can fetch them and follow their links, but search engines should index the canonical pages rather than a duplicate documentation dump.

## Caching and resource use

Markdown and text discovery responses include:

| Header | Value or meaning |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, or `text/plain; charset=utf-8` for discovery text. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | A quoted SHA-256 digest of the representation. |
| `X-Markdown-Tokens` | A rough estimate of characters divided by four, rounded up; not a model-specific tokenizer count. |

`If-None-Match` supports matching strong or weak validators, multiple validators, and `*`. A match returns `304` without a body. `HEAD` returns representation headers without a body.

The published Markdown inventory is compiled into the release. Requests do not perform content translation, read source files, load an authenticated account, or render a LiveView. No User-Agent impersonation is needed to access these public representations.

## Operational boundaries

Markdown negotiation does not provide access to account or project dashboards. Existing account-browsing rate limits and Turnstile checks remain separate protections.

Production edge rate limits apply to both `GET` and `HEAD`. Verified crawlers are still rate-limited. Excess requests receive a rate-limit response rather than a browser challenge; readers should slow down and retry later. Shared caching and conditional requests do not exempt clients from rate limits.

Crawler policy changes in the repository take effect only after the application and relevant infrastructure configuration are deployed.
