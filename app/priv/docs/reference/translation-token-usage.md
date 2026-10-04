%{
  title: "Translation token usage",
  summary: "Understand token accounting and project, language, and source-file breakdowns.",
  category: "reference",
  section: "translation",
  order: 12
}
---

## Dashboard

Open **Settings → Models → Token usage** to see provider-reported usage for generative translations. Access requires permission to read model settings.

The dashboard supports the last 7, 30, or 90 calendar days, including today, in UTC. Model, project, and language filters apply to the totals, daily chart, and breakdown. Search applies only to breakdown rows. The selected period, dimension, filters, search, sorting, and page are preserved in the URL.

## Metrics

| Metric | Meaning |
| --- | --- |
| Input tokens | Input processed by the provider, including reported cache reads and cache writes. |
| Output tokens | Provider-reported output, including reasoning when the provider includes it in its output count. |
| Cached input tokens | Cache reads. A subset of input tokens, not an additional charge in the total. |
| Total tokens | Input tokens plus output tokens. |
| Responses | Responses with both input and output counts and a positive token total. Zeroed missing-usage fallbacks are ignored. |

Token counts are not monetary costs. Providers can charge different rates for input, output, cached input, and cache writes.

Each reported response is counted, including validation retries, quality-correction retries, and responses rejected for reaching their output limit. Skipped files and checkpoint hits that do not call a model add no usage. Failed requests without usage cannot be counted.

## Dimensions

- **Projects** groups usage by project. Use the project filter to scope all metrics to a single project.
- **Languages** groups by target locale, such as `es` or `ja`, across projects in the current scope.
- **Files** groups by source path and project. The same source file translated into multiple languages appears once; identically named files in different projects remain separate.

**Unassigned** keeps requests without project or source-path metadata visible. Repository translations supply both automatically. Single-content API requests can provide `project_id` and `source_path` for attribution; a project ID outside the authenticated account is treated as unassigned. Invalid or oversized optional metadata is unassigned without discarding the token counts.

## Coverage

Usage is collected from ReqLLM API-key and OAuth responses, Together completions, and completed local Codex turns. Only provider-reported counts are persisted. Local Pi sessions and decision-model evaluations are not included. Historical translations are not backfilled or estimated. Totals therefore describe recorded usage, not a complete provider invoice.

The ledger stores account, project, model identifier and handle, target locale, source path, counts, and timestamp. It does not store prompts, translated content, credentials, or raw provider responses. Usage recording failures are logged without interrupting translation.
