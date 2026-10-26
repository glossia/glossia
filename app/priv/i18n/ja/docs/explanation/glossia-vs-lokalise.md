%{
  title: "Glossia と Lokalise の比較",
  summary: "製品のローカライズを配信パイプラインに管理し、公開ソース、自社のモデルトークン、ネイティブ検証を活用します。",
  category: "説明",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**多言語コンテンツにおいてプロダクトリポジトリが権威として残る場合に Glossia を選択してください。** ストリング、ドキュメント、設定、およびそのチェックはすでにアプリケーションの進化と調和して変化しています。Glossia は変更をチームにホストされたエディタを出版権威にするよう求めるのではなく、その進化に言語の変更を添付します。

[Lokalise](https://lokalise.com/) は協働ローカライゼーション、翻訳管理、および開発者統合を提供します。Glossia の提案はより具体的です：リポジトリワークフローを維持し、自前のモデル認証情報を導入し、既存のチェックを再利用し、作業を実行しているシステムを検査します。

## Why choose Glossia

| Your priority | Glossia's advantage |
|---|---|
| Match software-delivery speed | Source changes drive translation work; proposed outputs return through a repository review workflow. |
| Own the implementation | Public source makes processing inspectable and supports modification and self-hosting under the license terms. |
| Use your own model tokens | Account-scoped provider credentials let you choose supported models without putting secrets into Git. |
| Validate real application content | Repository scripts can check the candidate where the application expects to find it. |
| Preserve a clear review boundary | Pull requests keep language changes visible in the same tooling used to review the product. |

## Keep language changes attached to product changes

A new UI message or documentation section is not an isolated translation task. It belongs to a product revision, uses its terminology, and must work with its structure.

Glossia reads repository-owned `L10N.md` configuration, uses content and context changes to identify stale translations, and proposes updates for review. Reviewers see actual files and diffs; the publishing pipeline remains yours.

Lokalise also has automation and Git integrations. Glossia's distinction is the intended system of record: your repository owns the published content and its delivery rules, while Glossia supplies language context and transformation mechanics.

## Bring your own tokens instead of hardwiring one model choice

Glossia lets you configure supported models using your own provider API tokens. A repository uses a stable model handle, so rotating credentials or updating the model behind that handle does not require changing every project.

Nested configuration and locale-specific guidance can select a different configured model for a particular area or language. This is explicit selection, not a promise of automatic provider failover. See [Account models](./account-models).

## Reuse validation that already knows your application

Your repository may already know how to detect invalid strings, malformed files, broken component attributes, or a documentation build failure. Glossia can invoke that knowledge through a configured validation command.

The candidate is temporarily placed at its real output path for the check. The previous target is restored after each validation attempt, and the accepted candidate is written afterward. Rejected output goes through the configured recovery budget rather than being accepted just because the text looks plausible.

Structural and repository checks do not prove every sentence is correct. They complement human language review and make that review part of a deliverable change. See [L10N.md](/docs/reference/l10n-md) and [Translation recovery](./translation-recovery).

## Public source and repository-owned outputs

Glossia はオープンコアモデルを採用しています。コアは [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) に基づき、その条件の下で商用利用、変更、配布、セルフホスティング、競合するホスト型サービスの提供が可能です。`ee/` のコードは閲覧できますが、オープンソースではありません。別の [Enterprise ライセンス](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) が適用され、本番環境での利用には書面による商用契約が必要です。

More importantly for daily delivery, your translated outputs stay in Git. You do not need an editing session in another product simply to publish the existing files you own.

Lokalise may fit a team that wants centralized browser editing and localization coordination. Glossia is the choice when **repository ownership, your own model tokens, and existing product checks** are the workflow you want to keep.

Test a representative change before switching systems. This page does not promise automatic migration or feature parity, or claim that Lokalise lacks automation or all provider options. See [Lokalise's documentation](https://docs.lokalise.com/) for its current capabilities.
