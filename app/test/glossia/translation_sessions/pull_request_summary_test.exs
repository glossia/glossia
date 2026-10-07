defmodule Glossia.TranslationSessions.PullRequestSummaryTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Failure
  alias Glossia.TranslationSessions.Progress
  alias Glossia.TranslationSessions.PullRequestSummary

  defp progress(events),
    do:
      Progress.fold(
        Enum.with_index(events, 1)
        |> Enum.map(fn {e, seq} -> Map.put(e, :seq, seq) end)
      )

  defp done(index, path, locale, opts \\ []) do
    [
      %{type: "item_started", index: index, output_path: path, locale: locale},
      %{
        type: "item_completed",
        index: index,
        output_path: path,
        model_calls: Keyword.get(opts, :calls, 1),
        glossary_applied: Keyword.get(opts, :glossary, []),
        quality: Keyword.get(opts, :quality)
      }
    ]
  end

  defp failed(index, path, locale, reason) do
    [
      %{type: "item_started", index: index, output_path: path, locale: locale},
      %{type: "item_failed", index: index, output_path: path, reason: reason}
    ]
  end

  defp run(sha, status, events, extra \\ %{}) do
    Map.merge(
      %{
        id: "run-#{sha}",
        commit_sha: sha <> "000000000",
        commit_message: "Change #{sha}\n\nDetails that stay out of the table.",
        status: status,
        outcome: nil,
        error: nil,
        url: "https://glossia.ai/tuist/tuist/-/sessions/run-#{sha}",
        progress: progress(events)
      },
      extra
    )
  end

  defp data(runs, usage \\ []) do
    %{
      repository: "tuist/tuist",
      branch: "glossia/translate-abc",
      default_branch: "main",
      translations_url: "https://glossia.ai/tuist/tuist/-/translations",
      runs: runs,
      usage: usage
    }
  end

  test "summarizes every run on the pull request, letting later runs win" do
    first =
      run(
        "aaaaaaa",
        "completed",
        [%{type: "plan_assessed", total: 3, needs_translation: 3, up_to_date: 0}] ++
          done(0, "docs/es/a.md", "es",
            calls: 2,
            quality: %{ratings: [%{label: "Accuracy", score: 8}]}
          ) ++
          done(1, "docs/ja/a.md", "ja", glossary: [%{term: "Cache", translation: "キャッシュ"}]) ++
          failed(2, "docs/es/b.md", "es", %{
            kind: "validation",
            validation_message: "invalid JSON"
          })
      )

    second =
      run(
        "bbbbbbb",
        "completed",
        [%{type: "plan_assessed", total: 3, needs_translation: 2, up_to_date: 1}] ++
          done(0, "docs/es/a.md", "es",
            calls: 3,
            quality: %{ratings: [%{label: "Accuracy", score: 10}]}
          ) ++
          done(1, "docs/es/b.md", "es")
      )

    body =
      PullRequestSummary.render(
        data([first, second], [
          %{
            model: "openai/Translator",
            responses: 1_234,
            input_tokens: 2_500_000,
            cached_tokens: 0,
            output_tokens: 98_765
          }
        ])
      )

    assert body =~
             "Glossia translated **3 files** into **2 languages** from **2 source commits** on `main`."

    assert body =~ "✅ **Up to date with `bbbbbbb`.** 1 file was already up to date."

    # The second run retranslated `a.md` and fixed `b.md`.
    assert body =~ "| `es` | 2 | 0 | 4 | 10.0/10 |"
    assert body =~ "| `ja` | 1 | 0 | 1 | — |"
    refute body =~ "## Needs attention"

    # Newest commit first, with only the first line of its message.
    assert body =~
             "| [`bbbbbbb`](https://github.com/tuist/tuist/commit/bbbbbbb000000000) | Change bbbbbbb | [completed](https://glossia.ai/tuist/tuist/-/sessions/run-bbbbbbb) | 2 |\n| [`aaaaaaa`]"

    refute body =~ "Details that stay out of the table"
    assert body =~ "<summary><strong>ja</strong> · 1 file</summary>"
    assert body =~ "| Cache | キャッシュ | 1 |"
    assert body =~ "| `openai/Translator` | 1,234 | 2,500,000 | 0 | 98,765 |"
  end

  test "reports a run in progress and the files that need attention" do
    current =
      run(
        "ccccccc",
        "running",
        [
          %{
            type: "plan_assessed",
            total: 4,
            needs_translation: 4,
            up_to_date: 0,
            queued: Enum.map(0..3, &%{index: &1, output_path: "docs/ko/#{&1}.md", locale: "ko"})
          }
        ] ++
          done(0, "docs/ko/0.md", "ko") ++
          failed(
            1,
            "docs/ko/1.md",
            "ko",
            Failure.from({:validation_failed, "every tag must appear exactly once: <g1/> (u2)"})
          ) ++
          [%{type: "item_started", index: 2, output_path: "docs/ko/2.md", locale: "ko"}]
      )

    body = PullRequestSummary.render(data([current]))

    assert body =~
             "🔄 **Translating `ccccccc`.** 1 of 3 files done in this run, 1 in progress, 1 queued."

    assert body =~ "## Needs attention"
    assert body =~ "| `docs/ko/1.md` | `ko` | every tag must appear exactly once |"
  end

  test "explains why the latest run stopped" do
    stopped =
      run(
        "ddddddd",
        "failed",
        failed(0, "docs/es/a.md", "es", %{kind: "provider-credit", scope: "session", status: 402}),
        %{
          error:
            "The model provider rejected the translation because the account has no credit left (HTTP 402). Add credits for the model provider and retry."
        }
      )

    body = PullRequestSummary.render(data([stopped]))

    assert body =~
             "⚠️ **The run for `ddddddd` did not finish.** The model provider rejected the translation"

    assert body =~ "1 file could not be translated; see below."
  end

  test "drops the file list when the description would be too long for GitHub" do
    locales = ~w(es ja ko ru ka zh_Hans zh_Hant yue_Hant)

    events =
      for {locale, l} <- Enum.with_index(locales),
          index <- 0..119,
          event <-
            done(
              l * 1_000 + index,
              "docs/#{locale}/a-very-long-directory-name/with-nested-sections/page-#{index}.md",
              locale
            ),
          do: event

    body = PullRequestSummary.render(data([run("eeeeeee", "completed", events)]))

    assert String.length(body) < 65_536
    assert body =~ "**960 files** into **8 languages**"
    assert body =~ "The full file list is too long for a pull request description."
    refute body =~ "## Translated files"
  end
end
