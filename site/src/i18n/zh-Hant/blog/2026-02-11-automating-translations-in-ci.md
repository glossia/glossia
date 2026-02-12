---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
從一開始，l10n 就致力於讓翻譯成為開發工作流程的自然組成部分。而非發布前才想起要做的事，也不是需要手動觸發的步驟，而是每次內容變更時，自動發生的事情。

這個想法很簡單：每次推送到 `main` 分支時，都會觸發一個 CI 作業，檢查是否有任何翻譯過時，如果有的話，就會產生新的翻譯並開啟一個 Pull Request。整個過程大約一分鐘內完成，並且適用於任何 CI 系統。

## 運作方式

流程包含三個步驟，每個步驟都直接對應 l10n 指令。

**1. 檢查是否有過時內容。** 執行 `l10n status`。此指令會將您原始檔案及其翻譯的當前狀態與 l10n 維護的鎖定檔案進行比較。如果所有內容都是最新的，作業就會提前退出。不浪費計算資源，不產生雜訊。

**2. 翻譯變更的內容。** 如果 `l10n status` 偵測到有過時內容，無論是因為原始檔案變更、上下文更新，或是完全缺少翻譯，就執行 `l10n translate`。這就是 LLM 發揮作用的地方：讀取您的原始內容，應用您在 `L10N.md` 檔案中編寫的上下文，並產生符合您專案語氣和術語的翻譯。

**3. 開啟 Pull Request。** 如果有任何檔案變更，則建立一個分支，提交更新的翻譯，然後開啟一個 Pull Request。如果翻譯 PR 已經存在，則更新它而不是建立重複的 PR。

我們特意開啟 Pull Request，而不是直接將翻譯推送到 `main`。這讓您有機會審查輸出、迭代 `L10N.md` 檔案中的翻譯上下文，並建立對代理工作流程的信心。一旦您足夠信任結果，目標是完全跳過 PR 步驟，直接將翻譯提交到 `main`，使整個過程完全不可見。

您還會希望跳過來自翻譯作業本身的提交（以避免無限迴圈）以及發布提交。

## 範例：GitHub Actions

這是一個使用 GitHub Actions 的具體範例，但同樣的邏輯適用於 GitLab CI、CircleCI、Buildkite 或任何其他 CI 系統：

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

您需要將您的 LLM API 金鑰作為密鑰添加到您的 CI 環境中。我們使用 Anthropic 的 Claude，因此我們的金鑰是 `ANTHROPIC_API_KEY`。如果您使用 OpenAI，請將其替換為 `OPENAI_API_KEY` 並相應地更新您的 `L10N.md` 配置。

## 為何這很重要

重要的是，開發人員永不被打斷。他們以原始語言編寫內容，開啟他們的 PR，獲得審查並合併。沒有額外的步驟，也沒有翻譯審核阻礙他們的工作。

是的，合併後會出現一個短暫的語言不一致窗口，即原始內容已更改但翻譯尚未跟上。對於大多數專案而言，這完全沒有問題。而且這個窗口很短暫：合併後一分鐘內，CI 就會偵測到變更並開啟一個包含新輸出的翻譯 PR。

最初，團隊中的某人會審查並合併該翻譯 PR。在這個階段，您會建立對結果的信心，並迭代您的 `L10N.md` 上下文檔案，以確保語氣和術語正確。隨著時間的推移，當您信任輸出時，您可以完全跳過 PR 步驟，直接將翻譯推送到 `main`，使整個過程不可見。

因為 l10n 會驗證其自身的輸出（語法檢查、保留符號驗證以及您配置的任何自訂指令），所以在您收到翻譯之前，它們就已經通過了品質門檻。

## 接下來：將人工審查轉化為語言記憶

現今，當審查者發現翻譯問題並手動修正時，該知識僅存在於 git diff 中。下次 l10n 翻譯類似的短語時，它無法得知這次修正。

我們希望改變這一點。我們正在探索如何將翻譯 PR 上的人工審查轉化為 l10n 可以應用於未來翻譯的語言記憶。這個想法很簡單：如果審查者在行動裝置情境下將「click here」更改為「tap here」，l10n 應該學習此偏好並在未來應用。

這不是要建立一個傳統的翻譯記憶庫。這是關於捕捉 Pull Request 審查中已經存在的反饋迴路，並將其反饋到翻譯上下文中。修正已經在您的儲存庫中發生。我們只需要讓它們「記住」。

我們仍在摸索其確切形式，但方向很明確：每一次人工審查都應該自動使未來的翻譯變得更好。

## 開始使用

如果您想為您的專案設定此功能，請安裝 l10n 並初始化您的配置：

```bash
mise use github:tuist/l10n
l10n init
```

在 `L10N.md` 中配置您的原始檔案和目標語言，在您的 CI 管道中添加翻譯作業，並將您的 API 金鑰設定為密鑰。從那時起，每次推送到 `main` 分支都將使您的翻譯保持同步。