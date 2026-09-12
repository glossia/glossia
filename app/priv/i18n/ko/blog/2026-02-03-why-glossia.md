%{
  title: "현지화는 과거에 머물러 있었습니다. 우리는 Glossia 를 만들어 이를 진전시켰습니다.",
  summary:
    "전통적인 현지화 도구는 오버헤드를 더하고 CI 파이프라인을 방해하며 벤더 생태계에 사용자를 고착시킵니다. 우리는 에이전트 기반 현지화 워크플로우가 어떤 형태일지 탐색하고 있습니다.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
다국어로 소프트웨어를 배포해 본 적이 있다면 그 과정을 아실 것입니다. 현지화 플랫폼을 선택하고 레포지토리를 연동한 후 나머지 시간을 동기화 관리에만 할애합니다. 콘텐츠가 나가면 번역 결과가 돌아오고, 그 사이사이에 문제가 발생합니다.

그 오버헤드, 저장소와로의 콘텐츠 왕복 일정은 오늘날의 현지화 도구를 사용하는 모든 팀이 부담하는 비용입니다. 사소해 보이지만 금요일 오후 6 시에 사이트 빌드를 깨트린 번역 PR 을 디버깅하는 당신일 때 그 실상을 느끼게 됩니다.

## 인터넷 이전 시대의 디자인을 계승한

대부분의 현지화 플랫폼은 현대 개발 워크플로우 이전의 개념을 기반으로 설계되었습니다. 번역 메모리. 퍼지 매칭. 독점 편집기 안에서 작업하는 인간 번역가들은 데이터베이스에서 유사한 문자열을 추천해주는 도구를 받습니다.

번역이 수동적이고 오프라인일 때에만 이 아이디어가 유효했습니다. 하지만 기업들은 번역 메모리를 공급자 잠금 장치로 만들었습니다. 당신의 이전 번역, 당신이 지불한 조직 지식은 그들의 플랫폼 속에 살아있습니다. 다른 공급자로 이동하는 것은 처음부터 시작하거나 작동하지 않는 내보내기 비용을 지불하는 것입니다.

그 결과로된 것은 인위적 마찰을 기반으로 한 산업입니다. 당신의 콘텐츠는 레포지토리를 떠나 블랙박스를 거쳐 타인의 일정대로 돌아옵니다.

## 단절된 피드백 고리

문제는 구조적입니다: 외부 현지화 도구는 CI 파이프라인을 실행할 수 없습니다. 그들은 당신의 린터, 빌드 단계, 링크 체크기, 프론트매터 스키마를 잘 모릅니다. 그들은 번역된 콘텐츠를 레포지토리로 밀어 넣고 최선의 결과를 기대합니다. 실제로 문제가 발생하면, 팀원 중 누군가는 당신의 현재 작업을 중단하고 번역 도구가 추가한 포맷팅 문제나 깨진 문법 또는 유효하지 않은 마크업 등을 수리해야 합니다.

LLM 과 에이전트 기반 경험은 이러한 워크플로우를 완전히 다시 고안할 기회를 제시합니다. 번역을 생성하고 검사를 수행하며 오류를 발견한 후 출력이 유효해질 때까지 재시도하는 에이전트. 이러한 긴밀한 피드백 루프는 모든 것을 바꿉니다.

But it only works if the content stays where it lives: in your repository. The moment you send it off to an external platform, translations come back on someone else's timeline, and the integration breaks. The feedback that could have been instant now takes hours or days. The context that made it useful is long gone. You lose the loop, and with it, the entire advantage that agentic workflows were supposed to give you.

## Observations that shaped Glossia

These frustrations didn't turn into Glossia on their own. The project grew out of deep experience in both development and localization, which brought clarity to problems that are hard to see from just one side. Understanding the linguistic workflows, the human dynamics of translation teams, and the reasons why existing tools ended up the way they did was essential.

Together, we kept arriving at the same observations: localization tooling was designed for a world without LLMs, without coding agents, and without CI pipelines. The entire model assumed that translation was something that happened outside the development workflow and got pushed back in. That made sense ten years ago. It doesn't anymore.

We started asking: **what if localization agents could work the same way coding agents do?**

We've been paying close attention to how [Anthropic](https://anthropic.com) Claude 와 에이전트 워크플로우를 고민합니다. 에이전트에게 도구 접근 권한을 주어 작업을 추론하게 하고, 자체 출력을 검증하며, 오류 시 반복하는 패턴은 로케라이자 와 놀라울 정도로 잘 맞습니다. 소스 파일, 프로젝트 컨텍스트, 번역 생성, 라인터 실행, 풀 리퀘스트 열기 전 문제 해결까지 가능한 번역 에이전트입니다. 그것은 환상이 아닙니다. 우리가 구축하는 워크플로우입니다.

## Glossia 는 소프트웨어 산업에 바치는 우리의 선물입니다.

우리는 Glossia 를 만들었습니다. 더 많은 소프트웨어가 현지화되어야 한다는 믿음이 있기 때문입니다.

복잡한 과정과 고비용 플랫폼은 로컬라이제이션을 소규모 팀, 인디 개발자, 그리고 사이드 프로젝트 접근이 어렵게 만듭니다. 번역 워크플로우가 구매 절차, 단어당 가격 협상, 프로젝트 매니저가 조율하는 인수인계 작업을 필요로 한다면, 대부분의 팀은 영어만 출시하고 일을 마치게 됩니다.

Glossia 는 이미 접근할 수 있는 모델을 사용합니다. 결과 검증도 우리 도구가 아닌 사용자 자신의 도구를 통해 이루어집니다.

우리는 로컬라이제이션이 테스트 환경만큼 자연스러워야 한다고 봅니다.

## 에이전트를 먼저, 인터페이스는 두 번째

핵심에 있어 Glossia 는 에이전트입니다. 우리는 터미널을 일차 인터페이스로 시작합니다. 가장 난해한 문제들이 먼저 해결되는 곳이기 때문입니다: 소스 파일 판독, 번역 생성, 체크 실행, 출력이 유효해질 때까지 반복합니다. 이는 바로 그 [OpenAI](https://openai.com) 이어서 [Codex](https://openai.com/index/openai-codex/) 그리고 [Anthropic](https://anthropic.com) 와 [Claude Code](https://docs.anthropic.com/en/docs/claude-code). 당신은 에이전트를 구축하고, 터미널을 제공하고, 작업을 하게 합니다.

하지만 터미널은 단지 첫 번째 인터페이스일 뿐, 유일한 것이 아닙니다. 우리는 현지화 품질에 기여하는 모든 사람이 개발자는 아니라는 것을 잘 알고 있습니다. 우리는 내부에서 자주 이를 논의합니다. 번역의 정확성, 톤, 문화적 뉘앙스를 가장 중요하게 여기는 사람들은 주로 언어 전문가나 콘텐츠 전문가이며, 브랜치, 컴파일, 또는 JSON 같은 개발 개념으로는 생각하지 않습니다.

그렇기 때문에 우리는 동일한 에이전트 위에 새로운 인터페이스를 구축하고자 합니다. 언어 전문가가 콘텐츠, 컨텍스트, 번역을 나란히 볼 수 있는 것입니다. 이들은 어떤 모델도 대체할 수 없는 인간적 판단을 가져옵니다. 다듬어야 할 부분들을 다듬습니다. 에이전트는 나머지를 처리합니다: 커밋, 검증, 그리고 풀 리퀘스트를 엽니다.

우리는 아직 모든 답을 가지고 있지 않으며, 이는 의도적입니다. 핵심을 놓친 UI 에 급급하기보다 신중하게 이를 구축하는 것을 선호합니다. 그러나 방향성은 명확합니다. Glossia 는 소프트웨어가 모든 언어로 구사하도록 만드는 일에 관심을 가진 모든 사람을 환영해야 합니다.

## 잠시 기다려 주세요

Glossia 는 아직 초기 단계입니다. 우리는 이를 공개적으로 구축 중입니다. 현지화에 대한 생각과 부합한다면 프로젝트를 주시해 주세요. 진행에 따라 더 많은 내용을 공유할 예정입니다.