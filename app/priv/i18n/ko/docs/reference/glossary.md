%{
  title: "용어집",
  summary: "L10N.md 및 각 언어의 오버라이드 파일에서 용어집 필드에 대한 참고 자료입니다.",
  category: "참조",
  section: "번역",
  order: 2
}
---
저장소 어휘집은 두 파일로 분할됩니다. Glossia 는 각 파일을 번역할 때마다 해당 계정의 서버 어휘집과 병합합니다. 보십시오 [어휘집](/docs/explanation/glossary) 두 어휘가 어떻게 결합하는지.

| 파일 | `glossary` 포함 | 예시 |
|---|---|---|
| `L10N.md` | 목록의 **용어**, 모든 언어마다 동일합니다. | `- source: commit` |
| `L10N/<locale>.md` | 용어에서 해당 용어의 **번역** 해당 언어입니다. | `commit: commit` |

## L10N.md 의 용어들

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

| 필드 | 유형 | 필수 | 설명 |
|---|---|---|---|
| `source` | string | yes | 소스 텍스트에 나타나는 용어입니다. |
| `definition` | string | no | 모델이 해당 매치가 실제로 이 개념인지 판단하기 위해 읽는 짧은 안내입니다. |
| `case_sensitive` | boolean | 아니오 | when `true`, 해당 용어는 작성된 정확한 경우에만 일치합니다. 기본값은 `false`. 이름 및 약어와 같은 경우 `API` 또는 `SDK`. |
| `id` | string | 아니오 | 안정 식별자. 에서 유래 `source` 생략 시 (\]`Version Control` 변경됩니다 `version-control`, `C++` 변경됩니다 `cplusplus`) 번역 키를 id 기준 으로 설정하여 이름을 변경 `source` 용어의 정체성을 잃지 않거나, 상위 용어에서 용어를 덮어쓰기 위해 `L10N.md`. |

용어는 번역을 포함하지 않습니다. 해당 용어를 가진 `targets` 필드는 거부됩니다: 번역은 언어 파일에 포함되어야 합니다.

## L10N/ 의 번역 내용<locale>.md

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

각 키는 용어의 `id` 또는 해당 용어의 `source`, 그리고 해당 언어의 승인된 번역입니다.

- 어떤 용어도 일치하지 않는 키는 `L10N.md` 이 언어 전용 용어로 선언합니다.
- 해당 언어에 번역이 없는 용어는 해당 언어의 서버 글로사리를 사용합니다.
- 이름을 번역하지 않으려면, 해당 이름을 그대로 매핑해야 합니다. 예를 들어 `Glossia: Glossia`.

## 중첩 파일

각 파일은 해당 디렉토리 체인의 용어집으로 번역됩니다:

- 중첩된 `L10N.md` 상속된 항목에 용어를 추가합니다. 동일한 `id`, 또는 동일한 `source` 없을 때 `id` 설정되면 해당 서브트리에 대해 상속된 것을 대체합니다.
- 중첩된 `L10N/<locale>.md` 상속한 항목에 번역을 추가하며, 둘이 선언한 용어에 대해서는自身的 번역이 우선합니다.

## 검증

용어사전이 유효하지 않으면 Glossia 는 영향받은 파일에 대해 서버 용어사전만 사용하여 번역하므로 오타가 번역을 막지 않습니다. 일반적인 원인:

- **누락됨 `source`.** 각 용어는 비어 있지 않은 것이 필요합니다.
- **중복 `id`.** 각 용어는 명시적으로 설정되거나 유도되더라도 고유 식별자로 연결되어야 합니다. `source`.
- **L10N.md 의 번역입니다.** 해당 용어에서 `targets`. 번역을 이동하세요. `L10N/<locale>.md`.
- **빈 번역입니다.** 빈 문자열로 매핑된 용어입니다. 대신 제외하십시오.
- **잘못된 형식 또는 타입입니다.** `glossary` 에 배열이어야 합니다. `L10N.md` 및 객체이어야 합니다. `L10N/<locale>.md`. 번역, `id`, 및 `definition` , 문자열이어야 합니다; `case_sensitive` 여야 합니다 `true` 또는 `false`.

## Glossia 가 기록하는 항목

각 번역 파일의 잠금 파일은 해당 파일을 구성한 사전 항목을 기록합니다:

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

- `applied` 파일과 일치한 항목을 나열합니다. 저장소 항목은 `repo:<id>`. 서버 항목은 `account:<id>`.
- `shadowed` 이 파일에서 저장소 항목이 서버 항목을 대체한 항목을 나열합니다.

용어 나 번역을 편집하면 사용하는 파일만 다시 번역됩니다.

## 참고

- [용어사전 정의](/docs/how-to/define-a-glossary): 단계별 가이드.
- [용어사전](/docs/explanation/glossary): 저장소와 서버 용어사전 이 결합하는 방식입니다.
- [L10N.md 참조](/docs/reference/l10n-md): 다른 frontmatter 필드입니다.