%{
  title: "용어집 정의하기",
  summary: "L10N.md 에서 용어를 선언하고 각 언어별 오버라이드 파일에서 승인된 번역을 명시하세요.",
  category: "가이드",
  section: "translation",
  order: 6
}
---
귀 팀에는 이미 구체적인 방식으로 번역해야 할 용어들: 영어로 유지되는 제품명, 선호된 형식의 기술 용어, 특정 톤을 지닌 브랜드 단어 등이 있습니다. 이를 레포지토리에 선언하면 Glossia 가 모든 향후 번역에 적용합니다.

글로사리는 이미 사용 중인 두 가지 종류의 파일에 존재합니다:

- `L10N.md` 선언하는 **용어**": 단어가 무엇인지와 그 의미를 설명합니다. 모든 언어에서 동일합니다.
- `L10N/<locale>.md` 선언하는 **번역** 하나의 언어를 위한 것입니다. 각 언어의 리뷰어는 자신의 파일을 관리합니다.

계정에도 Glossia 에서 사전이 있다면 번역 시 병합됩니다. 참조 [사전](/docs/explanation/glossary) 규칙에 대해 및 [어떤 용도 사용하는지](/docs/explanation/glossary#when-to-use-which).

## 1\. 용어를 L10N.md 에 선언

추가를 `glossary` 목록을 루트의 프론트매터에 `L10N.md`:

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

각 용어에는 `source`, 텍스트에 나타나는 단어입니다. 이는 `definition` 모델이 실제 의도하는 개념인지 매칭인지 판단하도록 돕습니다. `case_sensitive: true` 시킵니다 `API` 본문에는 \\"api\\" 를 매칭하지 않고 의도한 개념으로 매칭되도록 합니다.

## 2\. 각 언어별 파일에서 번역하기

생성 또는 열기 `L10N/<locale>.md` 당신의 옆에 `L10N.md` 및 각 용어를 승인된 번역과 매핑합니다:

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

키는 용어의 `source`. 용어에 번역이 없는 언어는 계정 사전으로 되돌리거나 모델을 선택하게 합니다.

## 3\. 한 언어만 필요한 용어를 추가하세요

언어 파일은 단어를 번역할 수 있는 `L10N.md` 선언하지 않습니다. 이 규칙은 해당 언어에만 적용됩니다:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 용어에 안정적인 id 를 부여하세요

같은 단어가 정확한 의미를 필요로 하거나 용어를 재명명할 때 `source` 나중에, 이를 위한 `id` 그리고 해당 ID 를 기준으로 번역을 매핑하고:

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

## 5\. 저장소 일부에 대한 용어집 다듬기

중첩된 `L10N.md` 또는 `L10N/<locale>.md` 부모 디렉토리에서 내용을 상속받아 하위 트리의 항목을 추가하거나 덮어쓸 수 있습니다:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

아래의 스페인어 파일 `marketing/` "commit"을 번역하여 `compromiso`; 나머지 저장소는 기존 번역 상태를 유지합니다. `commit`.

## 6\. 커밋 및 푸시

변경 사항을 커밋하고 푸시하세요. 다음 번역 실행 시, Glossia 는 추가하거나 변경한 용어를 사용하는 파일들만, 번역이 변경된 언어에서 재번역합니다. 해당 용어를 포함하지 않는 파일은 기존 번역을 유지합니다.

글로사리에 오류가 있으면, Glossia 는 영향 받는 파일의 저장소 글로사리를 무시하고 계정 글로사리만 사용하므로 [유효성 검사 규칙](/docs/reference/glossary#validation) 용어가 적용되지 않을 때입니다.

## 참고

- [용어집 참조](/docs/reference/glossary): 모든 필드 및 검증 규칙.
- [용어집](/docs/explanation/glossary): 저장소 및 계정용어집이 결합되는 방식입니다.
- [L10N.md 참조](/docs/reference/l10n-md): 나머지 메타데이터 필드입니다.