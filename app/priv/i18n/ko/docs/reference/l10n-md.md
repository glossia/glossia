%{title: "L10N.md", summary: "레포지토리 번역 설정 및 컨텍스트 참조.", category: "참조", order: 1}
---
`L10N.md` 는 Glossia 에 번역할 파일, 번역된 파일이 위치할 곳, 표적할 언어와 결과를 안내할 컨텍스트를 정의합니다. 레포지토리는 루트 파일을 비롯하여 서브디렉토리에 추가 범위가 있는 파일을 포함할 수 있습니다.

## Structure

각 파일은 두 부분으로 구성됩니다:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter between `---` markers.
2. 프론트마터 아래의 제품, 청중, 목소리, 또는 도메인 컨텍스트가 포함된 마크다운.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

공급자 자격 증명은 계정 설정에 있어야 하며, `L10N.md` 에서 절대 사용되지 않습니다. 선택적인 `model` 값은 계정 모델 핸들입니다.

## Frontmatter fields

| Field | Type | Required | Description |
|---|---|---|---|
| `source_language` | string | no | 이 범위에 대한 소스 로컬. 기본값은 `en` 입니다. |
| `model` | string | no | 계정 모델 핸들. 생략될 경우 Glossia 는 계정 기본값을 사용하며 명시된 핸들이 존재하지 않으면 오류를 보고합니다. |
| `sources` | map or list | for a top-level rule | 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | map or list | when sources are configured | 표적 로컬 코드. 맵은 로컬 코드와 언어 이름을 연동할 수 있습니다. |
| `output` | string | when no source mapping or `target_path` supplies a destination | 출력 파일 템플릿. |
| `target_path` | string | when no source mapping or `output` supplies a destination | 번역 파일의 기본 디렉터리 템플릿. |
| `translate` | list | no | 여러번 번역 규칙, 각각 고유한 소스와 선택적 오버라이드를 가진 것들. |
| `exclude` | list | no | 건너뛴 파일 패턴. |
| `preserve` | list | no | 변하지 않아야 하는 콘텐츠 종류, 예: 플레이스홀더나 일원 리소스 위치. |
| `frontmatter` | string | no | `preserve` ( 기본값) 또는 `translate`. |
| `prompt` | string | no | 이 범위나 규칙에 대한 추가 가이드. |
| `validation` | list | for file extensions without a built-in adapter | 유효성 검증 명령어禁忌還有是其引數. 명령어는 실제 표적 경로에서 검증 대상을 받아들이며 파일이 무효화될 경우 nonzero 상태를 반환해야 합니다. |
| `check_cmd` | string | no | 번역 워크플로우에 이용 가능한 검증 명령어. |
| `check_cmds` | map | no | 번역 워크플로우에 이용 가능한 이름 지정 검증 명령어. |
| `retries` | integer | no | 실패한 검증 시도 후 재시도 횟수. 기본값은 `2`. |
| `locale` | string | no | 로컬 전용 컨텍스트 파일에 연결된 로컬. |

알려지지 않은 프론트마터 필드는 무시됩니다.

## File formats

Glossia 는 마크다운, JavaScript Object Notation, YAML Ain't Markup Language, portable object, 및 일반 텍스트 파일에 대해 내장 처리를 제공합니다. 관련 `L10N.md` 가 `validation` 명령어를 명시하지 않는 한 기타 파일 확장식은 계획 과정에서 실패합니다. 이를 통해 자체 구조화된 형식을 제한 없는 텍스트로 조용히 취급하는 것을 방지합니다.

유효성 검증 명령은 검증 대상이 실제로 표적 경로에 임시로 작성된 후 실행됩니다. 이를 통해 리포지토리의 네이티브 파서, 컴파일러 또는 빌드 명령어를 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 표적을 복원하고 승인된 검증 대상만이 이후에 작성됩니다.

## Source mappings

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿에 매핑합니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

A source list is also valid, but it needs `output` or `target_path` to define the destination:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 대상 언어

목록은 각 로케일 코드를 언어 식별자로 사용합니다:

```yaml
targets:
  - es
  - ja
```

가독성 있는 언어 이름을 추가할 수 있는 맵도 있습니다:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| 변수 | 값 |
|---|---|
| `{locale}` 또는 `{lang}` | 표적 로케일 코드. |
| `{relpath}` | 패턴에 일치한 소스 경로 (상대 경로). |
| `{basename}` | 확장자 없는 소스 파일명. |
| `{ext}` | 앞의 점 제외 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹이 서로 다른 목적지나 점검을 필요로 할 때 `translate`를 사용합니다:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

규칙 값은 주변 파일에서 상속된 값을 대체합니다.

## 범위 지정 컨텍스트

Glossia 는 리포지토리 루트부터 소스 파일 방향으로 `L10N.md` 파일을 읽습니다:

- 상위 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉토리의 영역을 덮어씁니다.
- 마크다운 컨텍스트는 상위에서 하위로 누적됩니다.
- 로케일별 가이드와 로케일별 모델 핸들러는 `L10N/<locale>.md` 에 존재할 수 있습니다.

이는 리포지토리가 루트에 광범위한 톤 가이드를 유지하면서, 해당 콘텐츠에 영향을 주는 제품 영역 또는 로케일별 가이드를 콘텐츠 근처에 배치하게 됩니다.