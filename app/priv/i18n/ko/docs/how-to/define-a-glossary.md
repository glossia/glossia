%{
  title: "용어집 정의하기",
  summary: "L10N.md 에서 용어를 선언하고 각 언어별 오버라이드 파일에서 승인된 번역을 명시하세요.",
  category: "가이드",
  section: "translation",
  order: 6
}
---
YOUR team already has terms that must translate a specific way: product names that stay in English, technical terms with a preferred rendering, brand words that carry a specific tone. Declare them in your repository and Glossia applies them to every future translation.

A glossary lives in two kinds of files you already use:

- `L10N.md` 명시합니다 **terms**: what the word is and what it means. This is the same for every language.
- `L10N/<locale>.md` declares the **translations** for one language. Each language's reviewers own their own file.

계정이 Glossia 에서 사전도 가지고 있는 경우, 둘은 번역 시간에 합쳐집니다. 보려면 [사전](/docs/explanation/glossary) 규칙에 대해 및 [어느 것을 언제 사용하는지](/docs/explanation/glossary#when-to-use-which).

## 1\. L10N.md 에서 용어를 선언하세요

추가 `glossary` 목록을 루트 디렉토리의 frontmatter 에 `L10N.md`:

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

각 용어에는 `source`, 텍스트에 나타나는 단어입니다. 이는 `definition` 모델이 매칭이 정말로 의도한 개념인지 판단하도록 도와줍니다. `case_sensitive: true` 만듭니다 `API` 본문에서 "api" 와 겹치지 않는 매칭을

## 2\. 각 언어 파일에 번역합니다.

생성하거나 열기 `L10N/<locale>.md` 여러분의 바로 옆에 `L10N.md` 각 용어를 승인된 번역으로 매핑하세요:

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

키는 용어의 `source`. 용어에 대한 번역이 없는 언어는 계정용어집으로 대체하거나, 모델을 선택하게 합니다.

## 3\. 한 언어에만 필요한 용어를 추가하세요

언어 파일은 단어를 번역할 수 있습니다 `L10N.md` 선언하지 않았습니다. 규칙은 해당 언어에만 적용됩니다:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 용어에 안정적인 ID 를 부여하세요

같은 단어가 정밀한 의미를 필요로 하거나 용어를 나중에 변경하려 할 때 `source` 나중에 고유 식별자를 부여하고 `id` 그 ID 로 번역을 연결하세요:

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

## 5\. 리포지토리의 일부에 대한 사전을 세밀하게 조정하세요

중첩 `L10N.md` 또는 `L10N/<locale>.md` 상위 디렉토리에서 상속되며 서브트리 항목을 추가하거나 덮어쓸 수 있습니다:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

아래의 스페인어 파일 `marketing/` "commit" 번역어를 설정하세요 `compromiso`; 저장소의 나머지 파일은 기존 상태를 유지합니다 `commit`.

## 6\. Commit 및 push

변경사항을 Commit 하고 push 합니다. 다음 번역 실행 시 Glossia 는 번역이 변경된 언어 내에서 추가되거나 수정된 용어를 사용하는 파일 만 재 번역합니다. 해당 용어가 포함되지 않은 파일은 기존 번역을 유지합니다.

용어집에 오류가 있다면, Glossia 는 영향 받은 파일에 대해 저장소용어집을 무시하고 계정용어집 만 사용합니다. 다음으로 확인해야 합니다 [검증 규칙](/docs/reference/glossary#validation) 용어가 적용되지 않을 때는.

## 참고

- [사전 참조](/docs/reference/glossary): 모든 필드 및 유효성 검사 규칙.
- [사전](/docs/explanation/glossary): 저장소 및 계정 사전이 어떻게 결합되는지.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 프론트매터 필드.