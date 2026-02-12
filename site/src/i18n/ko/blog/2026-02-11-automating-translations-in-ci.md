---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
l10n이 존재하는 이유는 로컬라이제이션을 저장소 내에 유지하고 개발자 워크플로우와 긴밀하게 연결하기 위함입니다. 이 도구는 로컬 유효성 검사 및 자동화를 강조합니다.

l10n을 처음부터 중요하게 생각했던 것 중 하나는 번역이 개발 워크플로우의 자연스러운 부분처럼 느껴지도록 하는 것이었습니다. 릴리스 전에 잊지 않고 해야 할 일도 아니고, 누군가 수동으로 트리거해야 하는 단계도 아닙니다. 콘텐츠가 변경될 때마다 자동으로 발생하는 일입니다.

아이디어는 간단합니다. `main` 브랜치로 푸시할 때마다 CI 작업이 트리거되어 번역이 최신 상태인지 확인하고, 만약 그렇지 않다면 최신 번역을 생성한 다음 풀 리퀘스트를 엽니다. 이 전체 과정은 약 1분 안에 완료되며, 모든 CI 시스템에서 작동합니다.

## 작동 방식

이 워크플로우는 세 단계로 구성되며, 각 단계는 l10n 명령과 직접적으로 연결됩니다.

**1. 최신 상태가 아닌 것이 있는지 확인.** `l10n status`를 실행합니다. 이 명령은 소스 파일과 번역의 현재 상태를 l10n이 관리하는 락 파일과 비교합니다. 모든 것이 최신 상태라면, 작업은 즉시 종료됩니다. 불필요한 컴퓨팅 자원 낭비나 노이즈가 없습니다.

**2. 변경된 내용 번역.** `l10n status`가 소스 파일 변경, 컨텍스트 업데이트, 또는 번역 누락 등으로 인해 최신 상태가 아닌 것을 감지하면 `l10n translate`를 실행합니다. 여기서 LLM이 소스 콘텐츠를 읽고, `L10N.md` 파일에 작성한 컨텍스트를 적용하여 프로젝트의 톤과 용어를 준수하는 번역을 생성합니다.

**3. 풀 리퀘스트 열기.** 변경된 파일이 있다면, 브랜치를 생성하고, 업데이트된 번역을 커밋한 후 풀 리퀘스트를 엽니다. 이미 번역 PR이 존재하는 경우, 중복 생성을 피하고 해당 PR을 업데이트합니다.

번역을 `main`에 직접 푸시하는 대신, 의도적으로 풀 리퀘스트를 엽니다. 이를 통해 출력물을 검토하고, `L10N.md` 파일에서 번역 컨텍스트를 반복하여 개선하며, 에이전트 워크플로우에 대한 신뢰를 구축할 기회를 제공합니다. 결과물에 충분히 신뢰가 쌓이면, PR 단계를 완전히 건너뛰고 번역을 `main`에 직접 커밋하여 프로세스를 완전히 보이지 않게 만드는 것이 목표입니다.

또한 번역 작업 자체에서 발생하는 커밋(무한 루프 방지용)과 릴리스 커밋은 건너뛰어야 합니다.

## 예시: GitHub Actions

다음은 GitHub Actions를 사용한 구체적인 예시이지만, 동일한 로직이 GitLab CI, CircleCI, Buildkite 또는 다른 모든 CI 시스템에 적용됩니다.

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

CI 환경에 LLM API 키를 시크릿으로 추가해야 합니다. 우리는 Anthropic의 Claude를 사용하므로, 우리의 키는 `ANTHROPIC_API_KEY`입니다. OpenAI를 사용하는 경우, `OPENAI_API_KEY`로 교체하고 `L10N.md` 설정을 그에 맞춰 업데이트하십시오.

## 왜 이것이 중요한가

중요한 것은 개발자의 작업 흐름이 결코 중단되지 않는다는 점입니다. 개발자들은 소스 언어로 콘텐츠를 작성하고, PR을 열고, 검토를 거쳐 병합합니다. 추가 단계도 없고, 번역 게이트가 작업을 방해하지도 않습니다.

병합 후 소스 콘텐츠는 변경되었지만 번역이 아직 따라잡지 못한 짧은 기간 동안 언어적 불일치(linguistic inconsistency)가 발생할 수 있습니다. 대부분의 프로젝트에서 이는 완전히 괜찮습니다. 또한 이는 짧은 시간 동안만 지속됩니다. 병합 후 1분 이내에 CI가 변경 사항을 감지하여 최신 번역 출력물을 포함하는 번역 PR을 엽니다.

처음에는 팀원이 해당 번역 PR을 검토하고 병합합니다. 이 단계는 결과물에 대한 신뢰를 구축하고 `L10N.md` 컨텍스트 파일을 반복하여 톤과 용어를 올바르게 조정하는 단계입니다. 시간이 지남에 따라 출력물을 신뢰하게 되면, PR 단계를 완전히 건너뛰고 번역을 `main`에 직접 푸시하여 전체 프로세스를 보이지 않게 만들 수 있습니다.

l10n은 자체 출력물(구문 검사, 토큰 유지 검증 및 구성한 모든 사용자 정의 명령)을 검증하므로, 번역은 사용자에게 도달하기 전에 이미 품질 검사를 통과합니다.

## 다음 단계: 사람의 검토를 언어적 기억으로 전환

오늘날, 검토자가 번역 문제를 발견하고 수동으로 수정하면, 그 지식은 git diff에만 존재합니다. l10n이 다음에 유사한 문구를 번역할 때, 해당 수정 사항을 알 방법이 없습니다.

우리는 이를 바꾸고자 합니다. 우리는 번역 PR에 대한 사람의 검토를 l10n이 향후 번역에 적용할 수 있는 언어적 기억으로 전환하는 방법을 모색하고 있습니다. 아이디어는 간단합니다. 만약 검토자가 모바일 환경에서 \"click here\"를 \"tap here\"로 변경한다면, l10n은 그 선호도를 학습하고 앞으로 적용해야 합니다.

이것은 전통적인 번역 메모리 데이터베이스를 구축하는 것이 아닙니다. 이는 풀 리퀘스트 검토에 이미 존재하는 피드백 루프를 포착하여 번역 컨텍스트에 다시 주입하는 것입니다. 수정 사항은 이미 여러분의 저장소에서 발생하고 있습니다. 우리는 그 수정 사항이 지속되도록 만들어야 합니다.

우리는 아직 이에 대한 올바른 형태를 파악하고 있지만, 방향은 분명합니다. 모든 사람의 검토가 미래의 번역을 자동으로 더 좋게 만들어야 합니다.

## 시작하기

프로젝트에 이 기능을 설정하려면, l10n을 설치하고 설정을 초기화하십시오.

```bash
mise use github:tuist/l10n
l10n init
```

`L10N.md`에서 소스 파일과 대상 언어를 구성하고, CI 파이프라인에 번역 작업을 추가하며, API 키를 시크릿으로 설정하십시오. 그 시점부터 `main`으로 푸시할 때마다 번역이 동기화됩니다.