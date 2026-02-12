---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
`l10n` 从一开始就致力于让翻译成为开发工作流的自然组成部分。它不是你需要在发布前才想起做的事情，也不是需要手动触发的步骤。它只是在内容每次发生变化时，都能自动完成的事情。

这个理念很简单：每次推送到 `main` 分支都会触发一个 CI 任务，检查是否有翻译过时。如果发现过时，它就会生成最新的翻译并创建一个拉取请求（pull request）。整个过程大约一分钟就能完成，并且适用于任何 CI 系统。

## 工作原理

整个流程分为三个步骤，它们直接对应 `l10n` 命令。

**1. 检查是否有内容过时。** 运行 `l10n status`。该命令会将你的源文件及其翻译的当前状态与 `l10n` 维护的锁文件进行比较。如果所有内容都是最新的，任务将提前退出。没有计算资源浪费，也没有多余信息。

**2. 翻译变更内容。** 如果 `l10n status` 检测到有内容过时——无论是源文件发生变化、上下文更新，还是翻译完全缺失，都会运行 `l10n translate`。这是大型语言模型（LLM）发挥作用的地方：它会读取你的源内容，应用你在 `L10N.md` 文件中编写的上下文，并生成符合项目语调和术语的翻译。

**3. 创建拉取请求。** 如果有任何文件发生变更，就创建一个分支，提交更新后的翻译，并创建一个拉取请求。如果已经存在一个翻译拉取请求，则更新它而不是创建重复项。

我们特意创建一个拉取请求，而不是直接将翻译推送到 `main` 分支。这样做可以让你有机会审查输出，迭代 `L10N.md` 文件中的翻译上下文，并逐步建立对代理工作流的信任。一旦你足够信任结果，目标就是完全跳过拉取请求步骤，将翻译直接提交到 `main`，使整个过程完全无感知。

你还需要跳过来自翻译任务本身的提交（以避免无限循环）以及发布提交。

## 示例：GitHub Actions

以下是使用 GitHub Actions 的一个具体示例，但相同的逻辑也适用于 GitLab CI、CircleCI、Buildkite 或任何其他 CI 系统：

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

你需要将你的 LLM API 密钥作为秘密（secret）添加到 CI 环境中。我们使用 Anthropic 的 Claude，所以我们的是 `ANTHROPIC_API_KEY`。如果你使用 OpenAI，请将其替换为 `OPENAI_API_KEY` 并相应地更新你的 `L10N.md` 配置。

## 重要意义

重要的是，开发者永远不会被打断。他们用源语言编写内容，创建拉取请求，获得审查，然后合并。没有额外的步骤，也没有翻译流程阻碍他们的工作。

确实，合并后会有一个短暂的语言不一致窗口，即源内容已更改但翻译尚未同步。对于大多数项目而言，这完全可以接受。而且这个窗口持续时间很短：合并后不到一分钟，CI 就会捕获到变更并创建一个带有最新翻译的拉取请求。

最初，团队中的某个人会审查并合并这个翻译拉取请求。在这个阶段，你可以建立对翻译结果的信心，并迭代你的 `L10N.md` 上下文文件，以确保语调和术语正确无误。随着时间的推移，当你信任翻译输出时，你可以完全跳过拉取请求步骤，将翻译直接推送到 `main`，使整个过程无感知。

因为 `l10n` 会验证其自身输出（语法检查、保留令牌验证以及你配置的任何自定义命令），所以在翻译结果到达你面前之前，它们就已经通过了质量门。

## 后续计划：将人工审查转化为语言记忆

目前，当审阅者发现翻译问题并手动修复时，这些知识仅存在于 `git diff` 中。下次 `l10n` 翻译相似短语时，它无法得知这些修正。

我们希望改变这一现状。我们正在探索如何将翻译拉取请求中的人工审查转化为语言记忆，以便 `l10n` 可以将其应用于未来的翻译。这个理念很简单：如果审阅者在移动端情境中将“click here”修改为“tap here”，那么 `l10n` 应该学习这种偏好并在后续翻译中应用它。

这并非要构建传统的翻译记忆库。它旨在捕获已存在于拉取请求审查中的反馈循环，并将其反馈到翻译上下文中。这些修正已经在你的代码库中发生，我们只需要让它们固化下来。

我们仍在探索其具体实现方式，但方向很明确：每一次人工审查都应自动地使未来的翻译变得更好。

## 开始使用

如果你想为你的项目设置此功能，请安装 `l10n` 并初始化你的配置：

```bash
mise use github:tuist/l10n
l10n init
```

在 `L10N.md` 中配置你的源文件和目标语言，将翻译任务添加到你的 CI 流水线中，并将你的 API 密钥设置为秘密。从那时起，每次推送到 `main` 分支都将使你的翻译保持同步。