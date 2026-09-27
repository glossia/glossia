%{
  title: "용어집 정의",
  summary: "L10N.md 에 용어를 선언하고 각 언어의 오버라이드 파일에 승인된 번역을 명시하세요.",
  category: "사용법",
  section: "번역",
  order: 6
}
---
팀에는 이미 영어로 유지해야 하는 제품명, 선호하는 렌더링이 있는 기술 용어, 특정 톤을 지닌 브랜드 단어와 같이 특정 방식으로 번역해야 할 용어들이 있습니다. 이를 리포지토리에 선언하면 Glossia 가 모든 향후 번역에 이를 적용합니다.

용어집은 이미 사용 중인 두 종류의 파일에 존재합니다:

- `L10N.md` 선언합니다 **용어**: 단어가 무엇이고 그 의미가 무엇인지 설명합니다. 모든 언어에서 동일합니다.
- `L10N/<locale>.md` 선언합니다 **번역** 한 언어용입니다. 각 언어의 검토자는 자신의 파일을 관리합니다.

계정이 서버에 사전도 보유 중인 경우 두 가지는 번역 시점에 병합됩니다. 참조 [사전](/docs/explanation/glossary) 규칙 과 [어떤 것을 언제 사용하는지](/docs/explanation/glossary#when-to-use-which).

## 1\. L10N.md 에서 사전용어를 선언하세요

추가 `glossary` 리스트 를 루트의 프론트메타에 `L10N.md`:

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

각 용어에는 `source`, 텍스트에 그대로 표현된 단어입니다. 이 `definition` 모델이 매치가 실제로 의도한 개념인지 판단하는 데 도움이 됩니다. `case_sensitive: true` 만들고 `API` 본문 내 'api' 를 포함하지 않은 매칭으로

## 2\. 각 언어별 파일에서 번역합니다.

생성하거나 열기 `L10N/<locale>.md` 당신의 바로 옆에 `L10N.md` 각 용어를 승인된 번역으로 매핑합니다.

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

키는 용어의 `source`. 용어가 번역이 없는 언어의 경우 서버 용어집 으로 되돌리거나 모델이 선택할 수 있습니다.

## 3\. 한 언어 만 필요한 용어 추가

언어 파일은 정의되지 않은 단어를 번역할 수 있습니다. `L10N.md` 선언되지 않습니다. 해당 규칙은 해당 언어에만 적용됩니다:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 용어에 고정된 ID 할당

같은 단어가 정확한 의미를 필요로 하거나, 용어의 이름을 변경하고 싶다면, `source` 나중에, 고유한 식별자를 부여하고, `id` 그 ID 로 번역을 연결:

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## 5\. 저장소 일부의 용어집을 정제합니다

중첩된 `L10N.md` 또는 `L10N/<locale>.md` 상위 디렉토리로부터 상속받아, 서브트리 항목을 추가하거나 덮어쓰며:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

이 하위에 있는 스페인어 파일 `marketing/` "commit"을 번역하십시오 `compromiso`; 나머지 저장소는 유지합니다 `commit`.

## 6\. 커밋 및 푸시

변경 사항을 커밋하고 푸시하세요. 다음 번역 실행 시 Glossia 는 번역이 변경된 언어에서 추가되거나 변경된 용어를 사용하는 파일만 재번역하며, 해당 용어를 포함하지 않는 파일은 기존 번역을 유지합니다.

용어집에 오류가 있으면 Glossia 는 영향받은 파일의 저장소 용어집을 무시하고 서버 용어집만 사용하므로 확인해 [검증 규칙](/docs/reference/glossary#validation) 용어가 적용되지 않는 것으로 보일 때.

## 참고

- [어휘집 참조](/docs/reference/glossary): 모든 필드 및 유효성 검사 규칙입니다.
- [어휘집](/docs/explanation/glossary): 저장소와 서버 어휘집이 어떻게 결합되는지입니다.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 프런트매터 필드들입니다.