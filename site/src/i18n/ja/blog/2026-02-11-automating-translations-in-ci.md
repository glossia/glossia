---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
`l10n`の当初からの目標の一つは、翻訳を開発ワークフローの自然な一部にすることでした。リリース前に「やろう」と思い出すものでも、誰かが手動でトリガーしなければならないステップでもありません。コンテンツが変更されるたびに、自動的に発生するものです。

アイデアはシンプルです。`main`へのプッシュごとにCIジョブがトリガーされ、翻訳が古くなっていないかを確認し、もし古くなっていれば新しい翻訳を生成してプルリクエストを開きます。このプロセス全体は約1分で完了し、あらゆるCIシステムで動作します。

## 動作の仕組み

このフローは3つのステップから成り、それぞれが`l10n`コマンドに直接対応しています。

**1. 古くなっているものがないかを確認する。**
`l10n status`を実行します。これは、ソースファイルとその翻訳の現在の状態を、`l10n`が管理するロックファイルと比較します。すべてが最新であれば、ジョブは早期に終了します。無駄な計算もノイズもありません。

**2. 変更されたものを翻訳する。**
`l10n status`が、ソースファイルの変更、コンテキストの更新、または翻訳の完全な欠落によって何かが古くなっていると検出した場合、`l10n translate`を実行します。ここでLLMがその役割を果たします。ソースコンテンツを読み込み、`L10N.md`ファイルに記述されたコンテキストを適用し、プロジェクトのトーンと専門用語を尊重した翻訳を生成します。

**3. プルリクエストを開く。**
ファイルに変更があった場合、ブランチを作成し、更新された翻訳をコミットして、プルリクエストを開きます。もし翻訳用のPRがすでに存在する場合は、重複を作成する代わりにそれを更新します。

翻訳を`main`に直接プッシュするのではなく、意図的にプルリクエストを開きます。これにより、出力をレビューし、`L10N.md`ファイル内の翻訳コンテキストを反復し、エージェントワークフローに対する信頼を構築する機会が提供されます。結果を十分に信頼できるようになったら、PRステップを完全にスキップし、翻訳を直接`main`にコミットして、プロセスを完全に意識させないようにすることが目標です。

また、翻訳ジョブ自体から発生するコミット（無限ループを避けるため）やリリースコミットをスキップすることも推奨されます。

## 例: GitHub Actions

ここではGitHub Actionsを使った具体的な例を示しますが、同じロジックはGitLab CI、CircleCI、Buildkite、その他のCIシステムにも適用できます。

```yaml
name: Translate

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  translate:
    name: Translate
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v5

      - uses: jdx/mise-action@v2

      - name: Check translation status
        id: status
        run: |
          if l10n status; then
            echo "stale=false" >> "$GITHUB_OUTPUT"
          else
            echo "stale=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Run translations
        if: steps.status.outputs.stale == 'true'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: l10n translate

      - name: Create PR with translations
        if: steps.status.outputs.stale == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ -z "$(git status --porcelain)" ]; then
            exit 0
          fi
          BRANCH="l10n/update-translations"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add -A
          git commit -m "[l10n] Update translations"
          git push --force origin "$BRANCH"
          gh pr create \
            --title "[l10n] Update translations" \
            --body "Automated translation update." \
            --head "$BRANCH" \
            --base main
```

LLMのAPIキーをCI環境のシークレットとして追加する必要があります。弊社ではAnthropicのClaudeを使用しているため、`ANTHROPIC_API_KEY`を使用しています。OpenAIを使用している場合は、`OPENAI_API_KEY`に置き換え、`L10N.md`の設定もそれに合わせて更新してください。

## なぜこれが重要なのか

重要なのは、開発者の作業が中断されないことです。開発者はソース言語でコンテンツを書き、PRを開き、レビューを受けてマージします。余分なステップはなく、翻訳が作業をブロックすることはありません。

確かに、マージ後には一時的に言語的な不整合の期間が発生します。ソースコンテンツが変更されたにもかかわらず、翻訳がまだ追いついていない状態です。ほとんどのプロジェクトでは、これは全く問題ありません。そして、それは短期間で解消されます。マージから1分以内に、CIが変更を検知し、最新の出力を伴う翻訳PRを開きます。

最初は、チームの誰かがその翻訳PRをレビューし、マージします。これは、結果に対する信頼を築き、`L10N.md`コンテキストファイルを反復してトーンや用語を適切に調整する段階です。時間の経過とともに、出力に信頼を置けるようになれば、PRステップを完全にスキップし、翻訳を直接`main`にプッシュすることで、プロセス全体を意識させないようにすることができます。

`l10n`は自身の出力（構文チェック、トークン保持検証、および設定したカスタムコマンド）を検証するため、翻訳は開発者の手元に届く前にすでに品質ゲートを通過しています。

## 次のステップ: 人間によるレビューを言語的記憶に変える

現在、レビュー担当者が翻訳の問題を発見し手動で修正した場合、その知識はgitの差分の中にしか存在しません。`l10n`が次回同じようなフレーズを翻訳する際、その修正について知る術はありません。

私たちはこれを変えたいと考えています。翻訳PRにおける人間のレビューを、`l10n`が将来の翻訳に適用できる言語的記憶に変える方法を検討しています。アイデアはシンプルです。もしレビュー担当者がモバイルコンテキストで「click here」を「tap here」に変更した場合、`l10n`はその設定を学習し、以降の翻訳に適用すべきです。

これは従来の翻訳メモリデータベースを構築することではありません。プルリクエストのレビューにすでに存在するフィードバックループを捉え、それを翻訳コンテキストにフィードバックすることです。修正はすでにリポジトリ内で行われています。私たちはそれを定着させる必要があるだけです。

これに対する適切な形はまだ模索中ですが、方向性は明確です。人間のレビューはすべて、将来の翻訳を自動的に改善するべきです。

## はじめに

プロジェクトでこれをセットアップしたい場合は、`l10n`をインストールして設定を初期化してください。

```bash
mise use github:tuist/l10n
l10n init
```

`L10N.md`でソースファイルとターゲット言語を設定し、CIパイプラインに翻訳ジョブを追加し、APIキーをシークレットとして設定します。それ以降、`main`へのすべてのプッシュが翻訳を同期させます。