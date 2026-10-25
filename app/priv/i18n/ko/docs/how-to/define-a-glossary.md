%{
  title: "사전 정의",
  summary: "L10N.md 에서 용어를 선언하고, 각 언어별 오버라이드 파일에서 승인된 번역을 명시하세요.",
  category: "사용 설명",
  section: "translation",
  order: 6
}
---

귀하의 팀에는 이미 특정 방식으로 번역해야 하는 용어들이 있습니다: 영어로 남겨야 하는 제품 이름, 선호되는 렌더링이 있는 기술 용어, 특정 톤을 담은 브랜드 단어입니다. 저장소에 이를 선언하면 Glossia 가 모든 향후 번역에 적용합니다.

사전은 이미 사용 중인 두 가지 종류의 파일에 있습니다:

- `L10N.md` 는 **용어**를 선언합니다: 단어가 무엇이며 그 의미가 무엇인지. 이는 모든 언어에 동일합니다.
- `L10N/<locale>.md` 는 한 언어의 **번역**를 선언합니다. 각 언어의 검토자는 자신만의 파일을 가지며 이를 책임집니다.

계정이 Glossia 에 사전이 있다면 두 사서는 번역 시 Merge됩니다. 규칙과 [사전](/docs/explanation/glossary)에서 [어떤 용어를 언제 사용하는지](/docs/explanation/glossary#when-to-use-which) 확인하세요.

## 1. L10N.md 에서 용어 선언

루트 `L10N.md` 의 프론트매터에 `glossary` 목록을 추가합니다:

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

각 용어에는 문서에 그대로 나타나는 `source` (source)가 필요합니다. `definition` 는 모델이 매칭된 것이 뜻하는 개념인지 결정하는 데 도움이 됩니다. `case_sensitive: true` 는 `API` 가 "api" 와 매칭되지 않도록 문맥 내에서 보호합니다.

## 2. 각 언어의 파일에서 번역

루트 `L10N.md` 옆에 `L10N/<locale>.md` 를 생성하거나 여세요. 각 용어를 승인된 번역과 매핑하세요:

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

키는 용어의 `source` (source) 입니다. 용어의 번역이 없는 언어는 계정 사전으로 되돌아가거나 모델을 선택하게 합니다.

## 3. 단일 언어만 필요한 용어 추가

언어 파일은 `L10N.md` (L10N.md) 에 선언되지 않은 단어를 번역할 수 있습니다. 해당 규칙은 해당 언어에만 적용됩니다:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 용어에 안정적인 id 부여

동일한 단어가 정확한 의미를 필요로 하거나 용어의 `source` (source) 를 나중에 변경하고 싶다면, `id` (id) 를 부여하고 해당 id 로 번역을 매핑하세요:

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

## 5. 저장소 일부에 대한 사전 다듬기

중첩된 `L10N.md` 또는 `L10N/<locale>.md` 는 상위 디렉토리에서 상속되며 그 하위 폴더의 엔트리를 추가하거나 덮어쓸 수 있습니다:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

`marketing/` (marketing/L10N/es.md) 아래의 스페인어 파일은 "commit" 을 `compromiso` (compromiso) 로 번역하며, 저장소 나머지는 `commit` (commit) 를 유지합니다.

## 6. Commit and Push

변경을 Commit 이고 Push 합니다. 다음 번역 실행 시 Glossia 는 번역이 변경된 언어에서 추가하거나 변경한 용어를 사용하는 파일만 다시 번역합니다. 해당 용어를 포함하지 않는 파일은 기존 번역을 유지합니다.

사전에 오류가 있을 경우, Glossia 는 영향받은 파일의 저장소 사전을 무시하고 계정 사전만 사용합니다. 용어가 적용되지 않는다고 의심될 때 [유효성 검사 규칙](/docs/reference/glossary#validation)을 확인하세요.

## 참고

- [사전 참조](/docs/reference/glossary): 모든 필드와 유효성 검사 규칙.
- [사전](/docs/explanation/glossary): 저장소와 계정 사서가 결합되는 방식.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 프론트매터 필드.
