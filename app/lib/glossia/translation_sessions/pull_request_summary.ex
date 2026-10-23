defmodule Glossia.TranslationSessions.PullRequestSummary do
  @moduledoc """
  The description of a project's translation pull request.

  A project keeps one translation pull request, and every run that publishes to
  it adds work. The description is rebuilt from all of those runs each time the
  branch moves, so a reviewer sees, in one place, what was translated into
  which languages, from which source commits, how well it scored, which
  glossary terms guided it, what it cost, and what still needs attention.

  `body/1` loads everything for a session's pull request. `render/1` is pure,
  so the layout can be tested without a database or GitHub.
  """

  use GlossiaWeb, :verified_routes

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Translations.Failure
  alias Glossia.Translations.TokenUsage
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.Progress
  alias Glossia.TranslationSessions.TranslationSession
  alias GlossiaWeb.PublicURL

  # GitHub rejects pull request bodies over 65,536 characters.
  @max_body_length 60_000
  @max_files_per_language 100
  @max_commits 20
  @max_glossary_terms 25

  @doc "Builds the description for the pull request `session` publishes to."
  def body(%TranslationSession{} = session) do
    session = Repo.preload(session, project: :account)
    runs = runs(session)
    since = runs |> Enum.map(&(&1.started_at || &1.inserted_at)) |> Enum.min(DateTime)
    base_uri = PublicURL.base_uri()

    render(%{
      repository: session.project.github_repo_full_name,
      branch: session.publication_branch,
      default_branch: session.project.github_repo_default_branch || "main",
      translations_url:
        url(
          base_uri,
          ~p"/#{session.project.account.handle}/#{session.project.handle}/-/translations"
        ),
      runs:
        Enum.map(runs, fn run ->
          run
          |> Map.from_struct()
          |> Map.put(:progress, TranslationSessions.session_progress(run.id))
          |> Map.put(
            :url,
            url(
              base_uri,
              ~p"/#{session.project.account.handle}/#{session.project.handle}/-/sessions/#{run.id}"
            )
          )
        end),
      usage: TokenUsage.project_totals(session.project_id, since)
    })
  end

  # Every session that published to this pull request, oldest first. A session
  # that has not published yet only has itself.
  defp runs(%TranslationSession{pull_request_number: number} = session) when is_integer(number) do
    from(s in TranslationSession,
      where: s.project_id == ^session.project_id and s.pull_request_number == ^number,
      or_where: s.id == ^session.id,
      order_by: [asc: s.inserted_at]
    )
    |> Repo.all()
  end

  defp runs(session), do: [session]

  @doc """
  Renders the description from already loaded data:

    * `:repository`, `:branch`, `:default_branch`, `:translations_url`
    * `:runs` - sessions oldest first, each with `:progress` (a folded
      `Glossia.TranslationSessions.Progress` state) and `:url`
    * `:usage` - `Glossia.Translations.TokenUsage.project_totals/2` rows
  """
  def render(data) do
    summary = summarize(data.runs)

    full =
      [
        overview(summary, data),
        languages(summary),
        commits(data),
        files(summary, data),
        glossary(summary),
        failures(summary),
        usage(summary, data),
        reviewing(data)
      ]
      |> assemble()

    if String.length(full) <= @max_body_length do
      full
    else
      [
        overview(summary, data),
        languages(summary),
        commits(data),
        "_The full file list is too long for a pull request description. See the [translation runs](#{data.translations_url}) in Glossia._",
        failures(summary),
        usage(summary, data),
        reviewing(data)
      ]
      |> assemble()
    end
  end

  defp assemble(sections) do
    sections
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n\n")
    |> Kernel.<>("\n")
  end

  # ── Folding the runs ──────────────────────────────────────────────────────

  # Later runs win: a file translated again replaces its earlier entry, and a
  # file that failed and later succeeded is no longer a failure.
  defp summarize(runs) do
    latest = List.last(runs)

    {translated, failed} =
      Enum.reduce(runs, {%{}, %{}}, fn run, {translated, failed} ->
        run.progress
        |> Progress.items()
        |> Enum.reduce({translated, failed}, fn item, {translated, failed} ->
          case item.status do
            :done ->
              {Map.put(translated, item.output_path, Map.put(item, :run, run)),
               Map.delete(failed, item.output_path)}

            :failed ->
              {translated, Map.put(failed, item.output_path, item)}

            _other ->
              {translated, failed}
          end
        end)
      end)

    latest_items = Progress.items(latest.progress)

    %{
      latest: latest,
      translated: translated |> Map.values() |> Enum.sort_by(&{&1.locale, &1.output_path}),
      failed: failed |> Map.values() |> Enum.sort_by(&{&1.locale, &1.output_path}),
      running: Enum.count(latest_items, &(&1.status == :running)),
      queued: Enum.count(latest_items, &(&1.status == :queued)),
      up_to_date: latest.progress.skipped,
      planned: latest.progress.total
    }
  end

  # ── Sections ──────────────────────────────────────────────────────────────

  defp overview(summary, data) do
    files = length(summary.translated)
    locales = summary.translated |> Enum.map(& &1.locale) |> Enum.uniq() |> length()
    commits = data.runs |> Enum.map(& &1.commit_sha) |> Enum.uniq() |> length()

    headline =
      "Glossia translated **#{count(files, "file")}** into **#{count(locales, "language")}** " <>
        "from **#{count(commits, "source commit")}** on `#{data.default_branch}`."

    "## Summary\n\n" <> headline <> "\n\n" <> status(summary)
  end

  defp status(%{latest: %{status: status} = run} = summary)
       when status in ["pending", "running"] do
    done = Enum.count(Progress.items(run.progress), &(&1.status == :done))
    remaining = summary.running + summary.queued

    "🔄 **Translating #{commit_ref(run)}.** #{done} of #{done + remaining} files done in this run, " <>
      "#{summary.running} in progress, #{summary.queued} queued. This description updates as files are pushed."
  end

  defp status(%{latest: %{status: "completed"} = run} = summary) do
    skipped =
      if summary.up_to_date > 0,
        do: " #{count(summary.up_to_date, "file was", "files were")} already up to date.",
        else: ""

    "✅ **Up to date with #{commit_ref(run)}.**" <> skipped
  end

  defp status(%{latest: %{status: "failed"} = run} = summary) do
    failed =
      case summary.failed do
        [] -> ""
        failures -> " #{count(length(failures), "file")} could not be translated; see below."
      end

    "⚠️ **The run for #{commit_ref(run)} did not finish.** " <>
      (run.error || "The translation could not be completed.") <> failed
  end

  defp status(%{latest: run}), do: "⏸️ **The run for #{commit_ref(run)} was cancelled.**"

  defp languages(%{translated: []}), do: nil

  defp languages(summary) do
    failed = Enum.frequencies_by(summary.failed, & &1.locale)

    rows =
      summary.translated
      |> Enum.group_by(& &1.locale)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {locale, items} ->
        "| `#{locale}` | #{number(length(items))} | #{number(Map.get(failed, locale, 0))} | " <>
          "#{number(model_calls(items))} | #{quality(items)} |"
      end)

    Enum.join(
      [
        "## Languages",
        "",
        "| Language | Files translated | Failed | Model calls | Quality |",
        "| --- | ---: | ---: | ---: | --- |"
        | rows
      ],
      "\n"
    )
  end

  defp commits(%{runs: runs} = data) do
    rows =
      runs
      |> Enum.reverse()
      |> Enum.take(@max_commits)
      |> Enum.map(fn run ->
        translated = Enum.count(Progress.items(run.progress), &(&1.status == :done))

        "| #{commit_link(data, run)} | #{table_text(first_line(run.commit_message))} | " <>
          "[#{run_status(run)}](#{run.url}) | #{number(translated)} |"
      end)

    more =
      if length(runs) > @max_commits,
        do: ["", "_#{length(runs) - @max_commits} earlier runs are listed in Glossia._"],
        else: []

    Enum.join(
      [
        "## Source commits",
        "",
        "Every commit below changed translatable content and was translated into this pull request.",
        "",
        "| Commit | Change | Run | Files |",
        "| --- | --- | --- | ---: |"
        | rows
      ] ++ more,
      "\n"
    )
  end

  defp files(%{translated: []}, _data), do: nil

  defp files(summary, data) do
    sections =
      summary.translated
      |> Enum.group_by(& &1.locale)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {locale, items} ->
        rows =
          items
          |> Enum.take(@max_files_per_language)
          |> Enum.map(fn item ->
            "| #{file_link(data, item.output_path)} | #{number(item.turns || 0)} | " <>
              "#{length(glossary_terms([item]))} | #{quality([item])} |"
          end)

        more =
          if length(items) > @max_files_per_language,
            do: ["", "_and #{length(items) - @max_files_per_language} more._"],
            else: []

        Enum.join(
          [
            "<details>",
            "<summary><strong>#{locale}</strong> · #{count(length(items), "file")}</summary>",
            "",
            "| File | Model calls | Glossary terms | Quality |",
            "| --- | ---: | ---: | --- |"
            | rows
          ] ++ more ++ ["", "</details>"],
          "\n"
        )
      end)

    Enum.join(["## Translated files" | sections], "\n\n")
  end

  defp glossary(summary) do
    case glossary_terms(summary.translated) do
      [] ->
        nil

      terms ->
        rows =
          terms
          |> Enum.frequencies()
          |> Enum.sort_by(fn {{term, _translation}, files} -> {-files, String.downcase(term)} end)
          |> Enum.take(@max_glossary_terms)
          |> Enum.map(fn {{term, translation}, files} ->
            "| #{table_text(term)} | #{table_text(translation)} | #{files} |"
          end)

        Enum.join(
          [
            "## Glossary",
            "",
            "These terms from your glossary guided the translations:",
            "",
            "| Term | Translation | Files |",
            "| --- | --- | ---: |"
            | rows
          ],
          "\n"
        )
    end
  end

  defp failures(%{failed: []}), do: nil

  defp failures(summary) do
    rows =
      Enum.map(summary.failed, fn item ->
        "| `#{item.output_path}` | `#{item.locale}` | #{table_text(failure_reason(item.reason))} |"
      end)

    Enum.join(
      [
        "## Needs attention",
        "",
        "These files are not part of this pull request yet. Glossia retries them with the next change, or you can retry the run in Glossia.",
        "",
        "| File | Language | Reason |",
        "| --- | --- | --- |"
        | rows
      ],
      "\n"
    )
  end

  defp usage(summary, %{usage: usage}) do
    calls = model_calls(summary.translated)

    rows =
      Enum.map(usage, fn row ->
        "| `#{row.model}` | #{number(row.responses)} | #{number(row.input_tokens)} | " <>
          "#{number(row.cached_tokens)} | #{number(row.output_tokens)} |"
      end)

    table =
      case rows do
        [] ->
          []

        rows ->
          [
            "",
            "| Model | Responses | Input tokens | Cached input tokens | Output tokens |",
            "| --- | ---: | ---: | ---: | ---: |"
            | rows
          ]
      end

    Enum.join(
      [
        "## Usage",
        "",
        "The translated files took #{count(calls, "model call")}, including retries that validation rejected."
        | table
      ],
      "\n"
    )
  end

  defp reviewing(data) do
    """
    ## Reviewing this pull request

    - Glossia keeps this pull request current: every change to translatable content on `#{data.default_branch}` is added here, and only what changed is translated again. Merging it publishes the translations; closing it discards them, and the next change opens a new one.
    - Each translated file has a lockfile under `.glossia/` recording what it was translated from. Keep them together: Glossia uses them to tell which translations are current.
    - Every file passed Glossia's validation before it was pushed: its Markdown structure, code, links, and placeholders match the source.
    - To change how something is translated, update the glossary, voice, or `L10N.md` instructions in [Glossia](#{data.translations_url}) so later translations follow it too.
    """
    |> String.trim_trailing()
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp model_calls(items), do: items |> Enum.map(&(&1.turns || 0)) |> Enum.sum()

  defp glossary_terms(items) do
    items
    |> Enum.flat_map(&(Map.get(&1, :glossary_applied) || []))
    |> Enum.flat_map(fn entry ->
      term = field(entry, :term)
      translation = field(entry, :translation)
      if is_binary(term) and is_binary(translation), do: [{term, translation}], else: []
    end)
  end

  # The average of every rated dimension across `items`, out of ten. Items
  # translated without a quality assessment are left out.
  defp quality(items) do
    scores =
      items
      |> Enum.map(&Map.get(&1, :quality))
      |> Enum.reject(&is_nil/1)
      |> Enum.flat_map(&(field(&1, :ratings) || []))
      |> Enum.map(&field(&1, :score))
      |> Enum.filter(&is_number/1)

    case scores do
      [] -> "—"
      scores -> "#{Float.round(Enum.sum(scores) / length(scores), 1)}/10"
    end
  end

  defp failure_reason(reason) do
    failure = Failure.normalize(reason)
    Map.get(failure, :validation_message) || Failure.describe(failure)
  end

  defp field(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp field(_value, _key), do: nil

  defp run_status(%{status: "completed"}), do: "completed"
  defp run_status(%{status: "failed"}), do: "failed"
  defp run_status(%{status: "cancelled", outcome: "superseded"}), do: "continued by a newer run"
  defp run_status(%{status: "cancelled"}), do: "cancelled"
  defp run_status(_run), do: "running"

  defp commit_ref(%{commit_sha: sha}) when is_binary(sha), do: "`#{String.slice(sha, 0, 7)}`"
  defp commit_ref(_run), do: "the latest commit"

  defp commit_link(%{repository: repository}, %{commit_sha: sha})
       when is_binary(repository) and is_binary(sha) do
    "[`#{String.slice(sha, 0, 7)}`](#{github_url(repository, ["commit", sha])})"
  end

  defp commit_link(_data, run), do: commit_ref(run)

  defp file_link(%{repository: repository, branch: branch}, path)
       when is_binary(repository) and is_binary(branch) do
    "[`#{path}`](#{github_url(repository, ["blob"] ++ String.split(branch, "/") ++ String.split(path, "/"))})"
  end

  defp file_link(_data, path), do: "`#{path}`"

  defp github_url(repository, segments) do
    path =
      Enum.map_join(String.split(repository, "/") ++ segments, "/", fn segment ->
        URI.encode(segment, &URI.char_unreserved?/1)
      end)

    URI.to_string(%URI{scheme: "https", host: "github.com", path: "/" <> path})
  end

  defp first_line(nil), do: ""
  defp first_line(message), do: message |> String.split("\n", parts: 2) |> hd() |> String.trim()

  # Table cells cannot contain pipes or line breaks.
  defp table_text(text) do
    text
    |> to_string()
    |> String.replace("|", "\\|")
    |> String.replace(~r/\s*\n\s*/, " ")
  end

  defp count(n, singular), do: count(n, singular, singular <> "s")
  defp count(1, singular, _plural), do: "1 #{singular}"
  defp count(n, _singular, plural), do: "#{number(n)} #{plural}"

  defp number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp number(n), do: to_string(n)
end
