%{
  title: "Glossia 対 Phrase",
  summary: "公開ソース、自らのモデルトークン、および再利用可能なデリバリーチェックを備えたリポジトリネイティブな言語ワークフローを選択してください。",
  category: "説明",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**言語作業をプロダクトの配送システムに従うようにしたい場合は Glossia を選び、別途並列の翻訳管理プロセスを構築する必要はありません。** コンテンツを Git に保持し、独自認証情報を使ってサポートモデルを選択し、レポジトリが既に信頼しているチェックで結果を検証してください。

[Phrase](https://phrase.com/) は、ソフトウェア局および管理翻訳ニーズ向けの Phrase Strings と Phrase TMS を含む局査スイートを提供しています。Glossia は集中的アプローチを採用し、開発チームのために既存のレビューと交付ループに適合する言語 OS を提供します。

## Why choose Glossia

| Your priority | Glossia's advantage |
|---|---|
| Deliver language changes with software | Repository changes drive localization, and outputs return as reviewable changes. |
| Inspect and own the processing | Public source exposes the application and deployment implementation, with modification and self-hosting allowed under the license terms. |
| Bring your own tokens | Configure your own supported model-provider credentials; select models through account handles in repository configuration. |
| Reuse validation pipelines | Run repository-native checks on translation candidates instead of treating linguistic approval as proof that a file will build. |
| Keep durable ownership | Published files, configuration, and pull-request history remain with the repository. |

## Make localization part of continuous delivery

Glossia's change detection avoids repeating translation work for unchanged inputs. Its repository workflow keeps one open translation pull request per project and publishes progress in batches, so a fast-moving source repository does not need a new translation process for every small change.

The objective is not an unreviewed race to production. It is to make language work continuously reviewable and deliverable through the pipeline your team already uses.

Phrase offers APIs, integrations, and automation too. The advantage Glossia emphasizes is architectural alignment: the repository remains the content authority and the delivery boundary, rather than only being a place to synchronize the results of another workspace.

## Keep model choice and credentials under your control

Glossia accepts your own provider API tokens for supported models. Credentials stay in account settings; repositories select stable handles. A team can rotate a token or change the model behind a handle without rewriting its repository instructions.

Different content scopes and target languages can use different configured models. Optional decision models can assess complete translations and request correction, while humans remain responsible for linguistic judgment. See [アカウントモデル](./account-models) for the current behavior and limits.

## Your repository already knows what valid content means

A translation-management system's view of a string is not necessarily the application's view of a file. A repository may have its own parser, compiler, component rules, documentation build, and placeholder checks.

Glossia can reuse those checks through `L10N.md` 検証コマンド。It writes the candidate temporarily to its real target path for validation and accepts it only after the required checks pass. The command and its dependencies must be available in the execution environment.

This lets the team extend its existing quality boundary rather than maintain a separate definition of "valid" solely inside a translation workspace. See [L10N.md](/docs/reference/l10n-md).

## Public implementation, not a black box

Glossia's application, CLI, SDK, and deployment sources are public. You can inspect how content is handled and modify or self-host the implementation under the [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). The license restricts competing hosted services and is not an unrestricted open-source license.

A broader translation suite can make sense for specialist translation operations and complex coordination. If your priority is **独自のトークンとリポジトリチェックによるソフトウェア配信速度の同期**, Glossia is designed to keep that workflow direct.

Moving an established translation program still requires a plan for its memories, terminology, and history. This page does not promise an automatic Phrase importer or full suite parity, or assert that Phrase lacks all equivalent integrations. Consult [Phrase のドキュメント](https://support.phrase.com/) for the specific product's current capabilities.
