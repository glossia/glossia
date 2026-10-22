%{
  title: "용어집 정의하기",
  summary: "L10N.md 에서 용어를 선언하고, 각 언어별 오버라이드 파일에서 승인된 번역을 명시하세요.",
  category: "사용 가이드",
  section: "translation",
  order: 6
}
---

귀하의 팀에는 이미 영어로 유지되거나 미리 선택한 형태로 번역되어야 할 용어가 있습니다. 해당 용어들을 저장소에 선언하면 Glossia 가 이를 향후 모든 번역에 적용합니다.

고사전은 이미 사용 중인 두 가지 종류의 파일에서 존재합니다.

- `L10N.md` 은 **용어**의 단어가 무엇이며 그 의미는 무엇인지 선언합니다. 이는 모든 언어에서 동일합니다.
- `L10N/<locale>.md` 은 한 언어에 대한 **번역**를 선언합니다. 각 언어의 검토자는 자신의 파일을 소유합니다.

계정에도 Glossia에 고사전이 있다면, 두 가지는 번역 시간에 병합됩니다. 규칙과 [고사전](/docs/explanation/glossary)을 보고 사용하기에 [올바른 시기와 방법](/docs/explanation/glossary#when-to-use-which)을 참조하세요.

## 1. L10N.md 에서 용어를 선언합니다

프론트매터에 `glossary` 목록을 추가합니다. 루트 `L10N.md` 에:

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

각 용어에는 `source`가 필요합니다. 텍스트에서 나타나는 단어입니다. `definition`는 모델이 해당 용어가 실제로 의도하는 개념과 일치하는지 판단하는 데 도움이 됩니다. `case_sensitive: true`는 `API`를 일치시키되, 본문에 "api"는 일치시키지 않습니다.

## 2. 각 언어의 파일에서 번역합니다

`L10N.md` 옆에 `L10N/<locale>.md` 을 생성하거나 열고 각 용어를 승인된 번역으로 매핑합니다:

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

키는 용어의 `source`입니다. 용어에 해당 번역이 없는 언어는 계정 고사전을 되돌리거나 모델에게 선택하게 됩니다.

## 3. 한 언어만을 위한 용어를 추가합니다

언어 파일은 `L10N.md` 에서 선언하지 않은 단어를 번역할 수 있습니다. 그 규칙은 해당 언어에만 적용됩니다:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 용어에 안정적인 식별자를 부여합니다

같은 단어가 정확한 의미를 필요로 하거나, 나중에 용어의 `source` 을 재명명하고 싶다면 `id`를 부여하고 해당 식별자로 번역을 키우세요:

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

## 5. 리포저토리의 일부에 대한 고사를 세밀하게 다듬습니다

호스팅된 `L10N.md` 또는 `L10N/<locale>.md` 는 상위 디렉토리에서 상속되며 서브트리에 대한 엔트리를 추가하거나 오버라이드할 수 있습니다:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

`marketing/` 하위의 스페인어 파일은 "commit" 을 `compromiso` 로 번역합니다. 리포저토리의 나머지는 `commit` 을 유지합니다.

## 6. 커밋 및 푸시

변경 사항을 커밋한 후 푸시합니다. 다음 번역 실행 시, Glossia 는 번역이 변경된 언어에만 해당 용어가 포함된 파일을 재번역합니다. 해당 용어를 포함하지 않는 파일은 기존 번역을 유지합니다.

고사에 실수가 있으면, Glossia 는 영향 받은 파일에 맞춰 리포저토리 고사전을 무시하고 계정 고사전만 사용하므로 [검증 규칙](/docs/reference/glossary#validation) 을 확인하세요.

## 참고 사항

- [고사전 참조](/docs/reference/glossary): 모든 필드 및 검증 규칙.
- [고사전](/docs/explanation/glossary): 리포저토리와 계정 고사전이 결합되는 방식.
- [L10N.md 참조](/docs/reference/l10n-md): 다른 프론트매터 필드.
