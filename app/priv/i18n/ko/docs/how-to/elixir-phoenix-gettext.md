%{
  title: "Elixir 와 Phoenix (Gettext)",
  summary: "Gettext 번역을 구성하고, 카탈로그 메타데이터를 보존하며 병합 충돌을 줄입니다.",
  category: "가이드",
  section: "ecosystems",
  order: 1
}
---

기존 Elixir 또는 Phoenix 애플리케이션을 [Gettext](https://hexdocs.pm/gettext/) 를 사용하여 Glossia 와 연동하고 카탈로그를 병합 친화적으로 유지하려면 이 가이드를 사용하세요. `mix.exs` 를 포함하는 디렉터리에서 Mix 명령을 실행하세요.

## 1. 결정적 추출 구성

`mix.exs` 개최의 기존 `project/0` 구성에 다음 옵션을 추가하세요:

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

이미 사용하는 다른 Gettext 옵션도 그대로 유지하세요. `sort_by_msgid: :case_sensitive` 은 Glossia 에서 사용하는 Gettext 버전에 의해 지원됩니다. 다른 프로젝트에 적용할 때 의존성의 [추출 옵션들](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) 을 확인하세요.

템플릿과 지역 파일을 재생성하세요:

```sh
mix gettext.extract --merge
```

단일차 표준화를 구문 변경과 별도로 검토하고 커밋하세요. 메시지 순서는 변경되지만 기존 번역은 변경되지 않아야 합니다. 열린 풀 리퀘스트와 torchvision 하여 카탈로그가 동일한 순서로 업데이트될 수 있도록 이 표준화를 조정하세요.

정렬은 모든 추가를 파일 끝에 추가하는 대신 독립적인 새로운 메시지를 정규 위치에 배치합니다. 참조 줄 번호를 생략하면 코드가 이동할 때 관련 없는 차이를 피하고 소스 파일 참조는 유지됩니다. 이 옵션들은 충돌을 줄이지만, 동일한 메시지에 대한 충돌을 없애거나 모든 삽입 쌍이 자동으로 병합되도록 보장할 수는 없습니다.

## 2. 애플리케이션 소스 대신 템플릿 번역

`L10N.md` 을 `mix.exs` 옆에 생성하거나 기존 구성에 다음 매핑을 추가하세요:

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

애플리케이션에 있는 도메인만 포함하세요. 추가 도메인에 대한 매핑을 각 추가 도메인에 대해 하나씩 추가하세요, `dashboard_projects.pot` 예시. 목적지는 디렉터리입니다: 포트어블 오브젝트 핸들은 `default.po`, `errors.po` 및 기타 일치하는 도메인 파일 이름을 그곳에 작성합니다.

`.pot` 템플릿을 소스로, `.po` 지역 파일을 출력으로 사용하세요. 한 번 번역된 지역을 다른 지역의 소스로 사용하지 마세요. 중첩 설정에 대한 정보는 [L10N.md 참조](/docs/reference/l10n-md) 를 확인하고, [기초 시작 튜토리얼](/docs/tutorials/getting-started) 을 통해 레포지토리를 Glossia 와 연동하세요.

## 3. 변경을 게시하기 전에 추출

풀 리퀘스트가 다음 호출 `gettext`, `dgettext`, 또는 `ngettext` 를 변경할 때:

1. 애플리케이션 코드를 업데이트하세요.
2. `mix gettext.extract --merge` 를 실행하세요.
3. 코드 변경 사항과 함께 템플릿과 지역 사이즈 차이를 검토하세요.
4. 풀 리퀘스트 병합 전에 생성된 변경 사항을 커밋하세요.

변경 사항을 병합한 후 Glossia 는 업데이트된 템플릿을 번역하고 번역 전용 풀 리퀘스트에 지역 변경 사항을 게시합니다. 해당 번역은 저장소의 일반적인 프로세스를 통해 검토하세요.

`msgid` 과 `msgctxt` 를 소스 식별자로 유지하세요. 필요한 복수형 변형을 포함한 `msgstr` 값을 번역하세요. 인터폴레이션 플레이스홀더, 복수형 헤더, 소스 참조, 번역가 주석, 및 플래그를 유지하세요. `fuzzy` 항목은 검토가 필요합니다: 검사 통과만을 위해 플래그를 제거하지 마세요, 변경된 메시지에 대해 이전 번역이 정확한지 자동으로 가정하지 마세요.

## 4. CI 에서 카탈로그 변경 사항 확인

실행:

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

추출 검증은 더 이상 애플리케이션 소스와 일치하지 않는 템플릿이나 지역 파일을 포착합니다. 컴파일러는 Gettext 가 카탈로그를 컴파일할 수 있는지 확인합니다. 두 명령어는 모두 언어적 품질을 검증하거나 모든 메시지에 대해 검토된 번역이 있는지 보증하지 않습니다.

추출이 오래된 파일을 보고하면 로컬에서 재생성하고 차이도를 검토한 후 커밋하세요. 검사를 우회하거나 번역 작업자가 소스 매칭 불일치를 숨기기 위해 템플릿을 반복적으로 재작성하지 마세요.

## 5. 메시지 정체성으로 카탈로그 충돌 해결

기본 브랜치에서 브랜치를 업데이트할 때:

1. 의도된 UI 텍스트를 유지하면서 먼저 애플리케이션 소스 충돌을 해결하세요.
2. 현재 컨텍스트와 소스 메시지 정체성을 포함하여 (필시 포함되는) 복수형 식별자를 활용하여 양쪽 브랜치의 카탈로그 항목을 화해하세요. 기존 번역, 주석, 플래그, 및 복수형 형태를 유지하세요. 파서를 실행하기 전에 충돌 마커와 중복 항목을 제거하세요.
3. 해결된 소스에 대해 `mix gettext.extract --merge` 를 실행하세요.
4. 위 CI 검사를 실행하고 결과 카탈로그 차이를 검토하세요.

전체 측면을 맹목적으로 수락하고 텍스트 유니온 병합 드라이버를 활성화하거나 카탈로그를 연결하여 카탈로그 충돌을 해결하지 마세요. 이러한 접근 방식은 유효한 번역을 잃거나 중복 식별자를 만들거나 무효한 파일을 남길 수 있습니다. 재발하는 충돌에 대한 회귀 테스트를 추가하여 서로 다른 새로운 메시지가 있는 두 브랜치에서 카탈로그를 생성하고 Git 이 템플릿 및 번역 카탈로그를 모두 항목을 잃지 않고 병합하는지 확인하세요.
