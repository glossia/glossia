%{
  title: "용어집",
  summary: "L10N.md 와 각 언어의 오버라이드 파일 내 용어집 필드에 대한 참조입니다.",
  category: "참조",
  section: "translation",
  order: 2
}
---

저장소용어사전은 두 파일로 나뉩니다. Glossia 는 번역하每户 파일에 대해 계정의 용어사전과 병합합니다. 두 가지가 어떻게 결합되는지 [Glossary](/docs/explanation/glossary) 를 확인하세요.

| 파일 | `glossary` 빈칸 | 예시 |
|---|---|---|
| `L10N.md` | **용어** 목록으로, 모든 언어에서 동일합니다. | `- source: commit` |
| `L10N/<locale>.md` | 용어에서 해당 언어의 **번역**로 매핑됩니다. | `commit: commit` |

## L10N.md 에의용어

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
| `source` | string | yes | 소스텍스트에 나타나는 용어. |
| `definition` | string | no | 모델이 해당 일치가 실제이 개념인지 판단하는 짧은 지침. |
| `case_sensitive` | boolean | no | When `true`, term only matches in exact case written. Defaults to `false`. Use for names and acronyms such as `API` or `SDK`. |
| `id` | string | no | Stable identifier. Derived from `source` when omitted (`Version Control` becomes `version-control`, `C++` becomes `cplusplus`). Set it to key translations by id, to rename `source` without losing identity, or override term from parent `L10N.md`. |

번역은 용어를 포함하지 않습니다. `targets` 필드를 포함한 용어는 기각: 번역은 언어 파일에 있습니다.

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

각 키는 용어의 `id` 또는 `source`. 각 값은 해당 언어 승인 번역.

- `L10N.md` 에서 일치하는 용어가 없는 키는 이 언어 전용 용어로 선언됩니다.
- 언어 번역 없는 용어는 계정용어 사전으로 fallback.
- 이름 번역 없이 유지하려면 자신으로 매핑, 예: `Glossia: Glossia`.

## 중첩 파일

모든 파일 대 디렉토리 체인용어 사전 번역:

- 중첩 `L10N.md` 은 상속하여 추가 용어. 같은 `id`, `id` 없는 경우 같은 `source`, tree inherited 대체.
- 중첩 `L10N/<locale>.md` 상속원어 추가. 두측 사용 용어 번역 승리.

## 검증

Invalid glossary Glossia 문서 계정용어사전 번역, 오타 번역 차단. 끌어.

- **누락 `source`.** 모든 용어는 비어있지 않은 값을 갖춰야 합니다.
- **중복 `id`.** 모든 용어는 명시적으로 설정되거나 `source` 에서 유래되더라도 고유 식별자로 해결해야 합니다.
- **L10N.md 에 번역.** `targets` 가 있는 용어는 `L10N/<locale>.md` 으로 이동시키세요.
- **빈번한 번역.** 빈 문자열로 매핑된 용어는 제외하세요.
- **잘못된 모양이나 유형.** `glossary` 은 `L10N.md` 에서 목록이 되고 `L10N/<locale>.md` 에서 맵이어야 합니다. 번역, `id`, `definition` 은 문자 여야 하며, `case_sensitive` 은 `true` 또는 `false` 여야 합니다.

## Glossia 가 기록하는 내용

각 번역된 파일의 lockfile 은 이를 구성한 용어사전 항목을 기록합니다:

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

- `applied` 는 파일과 일치한 항목을 나열합니다. 저장소 항목은 `repo:<id>`, 계정 항목은 `account:<id>` 로 표시됩니다.
- `shadowed` 는 저장소 항목이 이 파일에서 대체한 계정 항목을 나열합니다.

용어 나 번역을 수정하면 이를 사용하는 파일만 재번역됩니다.

## 다음:

- [용어사전 정의하기](/docs/how-to/define-a-glossary): 단계별 가이드.
- [용어사전](/docs/explanation/glossary): 저장소 및 계정용어사전이 결합하는 방법.
- [L10N.md 참조](/docs/reference/l10n-md): 기타 frontmatter 필드.
