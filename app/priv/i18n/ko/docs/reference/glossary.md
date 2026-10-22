%{
  title: "용어집",
  summary: "L10N.md 와 각 언어의 오버라이드 파일의 용어집 필드에 대한 참고입니다.",
  category: "참고",
  section: "translation",
  order: 2
}
---

레포지토리 어휘표는 두 파일을 나누어 관리합니다. Glossia 는 번역하는 모든 파일에 대해 계정의 어휘표와 이를 병합합니다. 두 어휘표가 어떻게 결합하는지 [어휘표](/docs/explanation/glossary) 를 참조하세요.

| 파일 | `glossary` 보유 | 예시 |
|---|---|---|
| `L10N.md` | 각 언어마다 동일한 **단어** 를 나열하는 목록입니다. | `- source: commit` |
| `L10N/<locale>.md` | 용어를 해당 언어의 **번역** 으로 매핑한 매핑입니다. | `commit: commit` |

## L10N.md 의 용어

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| 필드 | 형식 | 필수 | 설명 |
|---|---|---|---|
| `source` | 문자열 | 네 | source 텍스트에 표시되는 용어입니다. |
| `definition` | 문자열 | 아님 | 모델이 일치 여부를 결정할 때 읽는 짧은 지침입니다. |
| `case_sensitive` | 부울 | 아님 | `true` 일 때, 용어는 작성된 대로 정확한 경우에만 일치합니다. 기본값은 `false` 입니다. 이름 및 약어인 `API` 또는 `SDK` 에 사용하세요. |
| `id` | 문자열 | 아님 | 생략될 때 `source` 에서 파생됩니다 (`Version Control` 는 `version-control` 로, `C++` 는 `cplusplus` 로 바뀝니다). ID 로 번역을 주요 요소로 설정하거나, 용어의 정체성을 잃지 않고 `source` 를 수정하거나, `L10N.md` 에서 용어를 덮어쓸 수 있습니다. |

용어는 번역을 포함하지 않습니다. `targets` 필드가 있는 용어는 거부됩니다: 번역은 언어 파일에 있습니다.

## L10N/<locale>.md 의 번역

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

각 키는 용어의 `id` 소스 또는 `source` 값이며, 각 값은 해당 언어의 승인된 번역입니다.

- `L10N.md` 에 정의되지 않은 항목과 일치하는 키는 해당 언어에만 해당되는 항목을 선언합니다.
- 언어에 번역이 없는 용어는 해당 언어의 계정 어휘표로 돌아가게 됩니다.
- 이름을 번역하지 않고 싶으면 본인으로 매핑하세요. 예를 들어 `Glossia: Glossia`.

## 중첩 파일

각 파일은 디렉토리 체인의 어휘표로 번역됩니다:

- 중첩 `L10N.md` 은 상속된 항목에 추가합니다. 동일한 `id` 이 있거나 `id` 가 설정되지 않았을 때 동일한 `source` 이 있으면 상속된 것을 대체합니다.
- 중첩 `L10N/<locale>.md` 는 상속받아 온 번역을 추가하며, 내 번역은 둘이 선언하는 용어에 우선합니다.

## 검증

어휘표가 유효하지 않으면 Glossia 는 영향받은 파일을 계정 어휘표만 사용하여 번역합니다. 이는 오타가 번역을 차단하지 않도록 합니다. 일반적인 원인:

- **.`source` 누락** 각 용어는 비어있지 않아야 합니다.
- **.`id` 중복** 각 용어는 고유 식별자로 해결되어야 합니다. 명시적으로 설정하거나 `source` 에서 파생된 경우입니다.
- **L10N.md 에 있는 번역** `targets` 가 있는 용어: 번역을 `L10N/<locale>.md` 로 이동하세요.
- **빈 번역.** 빈 문자열로 매핑된 용어입니다. 대신 제외하세요.
- **잘못된 형태 또는 형식.** `glossary` 는 `L10N.md` 에서 리스트, `L10N/<locale>.md` 에서 맵이어야 합니다. 번역, `id`, `definition` 는 문자열이어야 하며 `case_sensitive` 는 `true` 또는 `false` 이어야 합니다.

## Glossia 가 기록하는 내용

각 번역된 파일의락파일 은 해당 파일을 구성한 어휘표 항목을 기록합니다:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` 는 파일과 일치하는 항목을 나열합니다. 저장소 항목은 `repo:<id>` 로, 계정 항목은 `account:<id>` 로 표시됩니다.
- `shadowed` 는 해당 파일에 대해 저장소 항목이 대체한 계정 항목을 나열합니다.

용어이나 번역을 수정하면 해당 항목을 사용하는 파일만 다시 번역됩니다.

## 관련 항목

- [어휘표 정의](/docs/how-to/define-a-glossary): 단계별 가이드.
- [어휘표](/docs/explanation/glossary): 저장소 및 계정 어휘표가 어떻게 결합되는지.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 상단장면 필드.
