%{
  title: "コンテンツ改定",
  summary: "既存のコンテンツをその場で改善します。Glossia は提供されたコンテキストを使用して、明瞭さ、正確性、トーンをレビューし、レビュー用の改訂版を生成します。",
  order: 2,
  icon: "pencil",
  hero_cta_text: "始める",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "トーンと明瞭性",
      description: "エージェントはあなたの文章の読みやすさ、専門用語、ブランドの声との整合性をレビューします。",
      icon: "message-circle"
    },
    %{
      title: "非破壊",
      description: "改訂コンテンツは元のファイルを上書きすることも、別のパスへ書き出すことも可能です。あなたは常に出力先を制御します。",
      icon: "shield-check"
    },
    %{
      title: "フィードバックループ",
      description: "レビュアーは出力を修正し、コンテキストを更新し、各サイクルにおいて草稿と最終版のギャップを縮めます。",
      icon: "refresh-cw"
    }
  ]
}
---
## How revisioning works

The agent reads your source files and the context graph, merging local instructions (`L10N.md` files at the root or in subdirectories) with remote context (your account-level voice, terminology, and style settings). With the full picture assembled, it rewrites content for clarity, accuracy, and tone, then outputs the revised version ready for review.

## Context graph

Context in Glossia is a graph that spans your account and your repository. Account-level settings like voice and terminology provide a global baseline, while `L10N.md` files placed alongside your content add local overrides. The agent resolves this graph on every run, so your instructions stay consistent across files without repeating yourself. Reviews are incremental thanks to lockfiles that track what has already been processed, so only changed or new content gets revisited.

## Progressive refinement

Each review cycle makes the output better. Corrections feed back into context files, so repeated mistakes disappear and the output converges on your team's standard over time.