%{
  title: "용어집",
  summary: "L10N.md 및 각 언어의 오버라이드 파일 내 용어집 필드에 대한 참조",
  category: "참조",
  section: "translation",
  order: 2
}
---
저장소 사전은 두 개의 파일로 나뉩니다. Glossia 는 번역하는 각 파일마다 계정 사전과 병합합니다. 보십시오 [사전](/docs/explanation/glossary) 둘이 어떻게 결합하는지.

| 파일 | `glossary` 보유 | 예시 |
|---|---|---|
| `L10N.md` | 목록의 **용어**, 모든 언어마다 동일합니다. | `- source: commit` |
| `L10N/<locale>.md` | 용어에 대한 **번역** 해당 언어입니다. | `commit: commit` |

## L10N.md 용어

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

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `source` | string | yes | 원본 텍스트에 나타나는 용어입니다. |
| `definition` | string | no | 모델이 해당 매치가 실제로 이 개념인지 판단하기 위해 사용하는 짧은 지침입니다. |
| `case_sensitive` | boolean | no | 언제 `true`, 해당 용어는 작성된 대소문자 그대로 일치합니다. 기본값은 `false`, 이름 및 약어와 같은 `API` 또는 `SDK`. |
| `id` | string | no | 안정 식별자. 유래됨 `source` 생략 시 (`Version Control` 변환됩니다 `version-control`, `C++` 변환됩니다 `cplusplus`). id 를 기준으로 키 번역 설정, 이름 변경 `source` 용어의 정체성을 잃지 않거나, 부모 용어를 덮어쓰도록 `L10N.md`. |

용어에는 번역이 포함되지 않습니다. 번역이 포함된 용어는 `targets` 필드가 거부됩니다: 번역은 언어 파일에 포함되어야 합니다.

## L10N/의 번역<locale>.md

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

각 키는 용어의 `id` 또는 그것의 `source`, 그리고 각 값은 해당 언어의 승인된 번역입니다.

- 어떤 용어도 일치하지 않는 키는 `L10N.md` 이 언어에만 해당되는 용어를 선언합니다.
- 해당 언어에 번역이 없는 용어의 경우 해당 언어의 계정 용어사전을 참조합니다.
- 이름을 번역하지 않고 유지하려면, 예를 들어 자신을 매핑 `Glossia: Glossia`.

## 중첩 파일

모든 파일은 해당 디렉토리 체인의 용어집을 사용하여 번역됩니다:

- 중첩된 `L10N.md` 상속된 항목들에 용어를 추가합니다. 동일한 `id`, 또는 동일한 `source` 없을 때 `id` 설정되면, 해당 서브트리의 상속된 값을 대체합니다.
- 중첩된 `L10N/<locale>.md` 상속한 번역에 추가하며, 양쪽이 모두 선언한 용어에 대해서는 해당 번역이 우선합니다.

## 검증

용어집이 유효하지 않으면, Glossia 는 해당 파일을 계정용어집만으로 번역하므로 오타는 번역을 막지 않습니다. 일반적인 원인:

- **누락 `source`.** 각 용어는 비어있지 않은 값을 갖춰야 합니다.
- **중복 `id`.** 모든 항목은 명시적으로 설정되거나 유추된 고유 식별자로 해결되어야 합니다 `source`.
- **L10N.md 번역입니다.** 중복을 가진 `targets`. 번역을 이동하세요 `L10N/<locale>.md`.
- **빈 번역입니다.** 빈 문자열로 매핑된 용어입니다. 대신 제외하세요.
- **형식 또는 타입 오류입니다.** `glossary` 에서 리스트여야 합니다 `L10N.md` 및 맵이어야 합니다 `L10N/<locale>.md`. 번역은 `id`및 `definition` 문자열이어야 합니다; `case_sensitive` 이어야 합니다 `true` 또는 `false`.

## Glossia 가 기록하는 내용

각 번역 파일의 락파일 은 해당 파일을 구성한 용어집 항목을 기록합니다:

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

- `applied` 파일과 일치한 항목을 나열합니다. 저장소 항목은 `repo:<id>`, 계정 항목은 `account:<id>`.
- `shadowed` 이 파일에 대해 저장소 항목으로 교체된 계정 항목을 나열합니다.

용어나 번역을 편집하면 이를 사용하는 파일만 다시 번역됩니다.

## 참고

- [사전 정의](/docs/how-to/define-a-glossary): 단계별 가이드.
- [사전](/docs/explanation/glossary): 저장소와 계정 사전이 결합하는 방식.
- [L10N.md 참조](/docs/reference/l10n-md): 나머지 frontmatter 필드들.