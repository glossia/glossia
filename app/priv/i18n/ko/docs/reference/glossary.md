%{
  title: "용어집",
  summary: "L10N.md 및 각 언어의 오버라이드 파일의 용어집 필드에 대한 참조입니다.",
  category: "참조",
  section: "translation",
  order: 2
}
---

저장소 용어집은 두 개의 파일로 나뉩니다. Glossia 는 번역하는 모든 파일에 대하여 계정용リューム과 결합합니다. 두 용어집이 어떻게 결합되는지 [은 예](/docs/explanation/glossary)를 참조하세요.

| 파일 | `glossary` 보유함 | 예시 |
|---|---|---|
| `L10N.md` | 모든 언어에서 동일한 **용어** 목록입니다. | `- source: commit` |
| `L10N/<locale>.md` | 그 언어에서 용어와 그 **번역**을 매핑하는 맵입니다. | `commit: commit` |

## L10N.md 에 있는 용어

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

| 필드 | 형식 | 필수 여부 | 설명 |
|---|---|---|---|
| `source` | 문자열 | 필수 | 소스 텍스트에 나타나는 용어입니다. |
| `definition` | 문자열 | 선택 | 모델이 매치가 정말 이 개념인지 결정하기 위해 참조하는 짧은 안내입니다. |
| `case_sensitive` | 부울값 | 선택 | `true`, 용어는 정확히 작성된 경우에만 매치됩니다. 기본적으로 `false`, 사용합니다. 이름 및 약어 (예: `API` 또는 `SDK`) 에 사용할 수 있습니다. |
| `id` | 문자열 | 선택 | 고정식 식별자. 생략하면 `source`, `Version Control`, `version-control`, `C++`, `cplusplus`로 변환됩니다. 번역을 id 로 직접 키를 설정하고, `source`, 용어의 정체를 잃지 않고 이름을 변경하거나, 부모 `L10N.md` 용어를 강제 교체하기 위해 설정합니다. |

용어는 번역을 운반하지 않습니다. `targets` 필드를 벗어난 용어는 거부됩니다: 번역은 언어 파일에 있어야 합니다.

## L10N/<locale>.md 에 있으면서 번역됨

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

각 키는 용어의 `id` 또는 `source`, 각 값은 해당 언어에 대한 승인 번역입니다.

- `L10N.md` 중 어떤 용어도 매치하지 않는 키는 해당 언어 전용 용어를 선언합니다.
- 언어에서 번역이 없는 용어는 해당 언어의 계정용어집으로 넘어갑니다.
- 이름을 번역하지 않고 유지하려면, 맵 설명을 그 자체로 설정하면 됩니다. 예를 들어 `Glossia: Glossia`.

## 중첩 파일

각 파일은 해당 디렉토리 계열의 용어집으로 번역됩니다:

- 중첩된 `L10N.md` 은 상속받는 항목들에 용어를 추가합니다. 동일한 `id` 을 가진 용어이거나, `id` 가 설정되지 않았을 때 동일한 `source` 을 가진 용어는 해당 서브트리의 상속된 것을 대체합니다.
- 중첩 `L10N/<locale>.md` 은 상속된 번역에 새로운 번역을 추가하며, 둘 중 하나를 선언한 용어에 먼저 선택되는 번역이 우선합니다.

## 유효성 검사

용어집이 잘못되면 Glossia 는 영향 받은 파일은 계정용어집만 사용하여 번역하므로 오타도 번역에 방해되지 않습니다. 일반적인 원인:

- **.`source`배고픔 파일** 모든 용어는 비어있지 않은 것을 필요합니다.
- **.`id`중복 ID** 모든 용어는 명시적으로 설정되거나 `source`으로부터 유래했든 독자의 식별자로 해결해야 합니다.
- **L10N.md 에 번역 완료.** `targets`, 번역을 `L10N/<locale>.md`로 이동하여.
- **번역 비어있음.** 빈 문자열로 매핑된 용어입니다. 제외하는 것이 좋습니다.
- **형식 또는 타입 오류.** `glossary` 는 `L10N.md` 에서 리스트여야 하며 `L10N/<locale>.md` 에서 맵이어야 합니다. 번역, `id`, 및 `definition` 은 문자열이어야 하며 `case_sensitive` 은 `true` 또는 `false` 이어야 합니다.

## Glossia 가 기록하는 내용

각 번역된 파일의 락 파일에는 해당 파일을 구성한 용어집 항목들이 기록됩니다:

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

- `applied` 는 해당 파일에 매치된 항목들을 나열합니다. 저장소 항목은 `repo:<id>` 형식으로, 계정 항목은 `account:<id>` 형식으로 표시됩니다.
- `shadowed` 는 이 파일에 대해 저장소 항목이 대신한 계정 항목을 나열합니다.

용어 또는 번역을 편집하면 전지 사용 파일만 다시 번역됩니다.

## 관련 항목

- [용어집 정의](/docs/how-to/define-a-glossary): 단계별 가이드.
- [용어집](/docs/explanation/glossary): 저장소 및 계정용어집이 어떻게 결합되는지.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 프론트마터 필드.
