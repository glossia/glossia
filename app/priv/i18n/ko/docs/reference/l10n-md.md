%{title: "L10N.md", summary: "저장소 번역 설정 및 컨텍스트 참조", category: "참조", order: 1}
---
`L10N.md` Glossia 에 번역할 파일을 지정하고, 번역된 파일이 어디에 있는지, 어떤 언어를 목표로 할지, 그리고 작업 방향을 위한 컨텍스트가 무엇인지 안내합니다. 저장소는 루트 파일과 하위 디렉터리 내에 있는 추가 파일음을 포함할 수 있습니다.

## 구조

각 파일은 두 가지 부분으로 구성됩니다.

1. [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 마커 사이 `---` 프론트매터가 있습니다.
2. 프론트매터 아래의 Markdown 은 제품, 대상 독자, 톤 또는 도메인 컨텍스트가 포함됩니다.

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

제공자 자격증명은 계정 설정에만 있어야 하며, 절대로 `L10N.md`. 선택 사항 `model` 값은 계정 모델 핸들입니다.

## 프론트매터 필드

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아니요 | 이 범위의 소스 언어입니다 기본값은 `en`. |
| `model` | 문자열 | 아니요 | 계정 모델 핸들. Glossia 는 생략할 경우 기본 계정을 사용하고 명시된 핸들이 없을 경우 오류를 보고합니다.
| `sources` | 맵 또는 목록 | 상위 규칙의 경우 | 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다.
| `targets` | 맵 또는 목록 | 소스가 구성되었을 때 | 대상 로케일 코드. 맵은 로케일 코드를 언어 이름과 연결할 수 있습니다.
| `output` | 문자열 | 소스 매핑이 없거나 `target_path` 출력 대상 제공 | 출력 파일 템플릿. |
| `target_path` | 문자열 | 소스 매핑이 없을 때 또는 `output` 출력 대상 제공 | 번역된 파일의 기본 디렉터리 템플릿. |
| `translate` | 목록 | 없음 | 각기 다른 소스와 선택적 오버라이드를 가진 여러번 번역 규칙. |
| `exclude` | 목록 | 없음 | 생략할 파일 패턴. |
| `preserve` | list | no | 변경되지 않아야 하는 콘텐츠의 종류입니다. 예시: 플레이스홀더 또는 유니폼 리소스 로케이터. |
| `frontmatter` | string | no | `preserve` 기본적으로 또는 `translate`. |
| `prompt` | string | no | 이 범위 또는 규칙에 대한 추가 지침입니다. |
| `validation` | 목록 | 내장 어댑터가 없는 파일 확장자를 위한 | 검증 명령어 및 해당 인수가 포함되어 있습니다. 명령어는 실제 타겟 경로에서 후보를 받으며, 파일이 유효하지 않은 경우 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 없음 | 번역 워크플로우에 제공되는 확인 명령어입니다. |
| `check_cmds` | map | no | 번역 워크플로우에 사용 가능한 이름 지정된 체크 명령어. |
| `retries` | integer | no | 실패한 체크 후 재시도 횟수. 기본값은 `2`. |
| `locale` | 문자열 | 아니요 | Locale 이 Locale 기반 컨텍스트 파일에 연결된 경우 |

알 수 없는 frontmatter 필드는 무시됩니다.

## 파일 형식

Glossia 는 Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object 및 일반 텍스트 파일에 대해 내장 처리를 제공합니다. 다른 파일 확장자는 계획 실패하지 않는 한 적용 가능한 `L10N.md` 명령을 `validation` 선언해야 합니다. 이는 고유의 구조화된 형식을 제한 없는 텍스트로 은밀히 취급하는 것을 방지합니다.

검증 명령어는 후보가 실제 대상 경로에 임시적으로 작성된 후 실행됩니다. 이 명령어는 리포지토리의 내장 파저, 컴파일러 또는 빌드 명령어를 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 대상 경로를 복원하며 승인된 후보에만 이후에 작성합니다.

## 소스 매핑

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿으로 매핑하는 것입니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록 또한 유효하지만, 정의가 필요합니다 `output` 또는 `target_path` 대상 경로를 정의하기 위해:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 대상 언어

A list uses each locale code as its language identifier:

```yaml
targets:
  - es
  - ja
```

A map can add a readable language name:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| Variable | Value |
|---|---|
| `{locale}` or `{lang}` | Target locale code. |
| `{relpath}` | Source path relative to the matched pattern. |
| `{basename}` | Source filename without its extension. |
| `{ext}` | Source file extension without the leading dot. |

## 다중 규칙

Use `translate` when different content groups need different destinations or checks:

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

Rule values override values inherited from the surrounding file.

## 스코프 컨텍스트

Glossia reads `L10N.md` files from the repository root toward the source file:

- Parent settings provide defaults.
- A deeper file overrides fields for its directory.
- Markdown context is accumulated from parent to child.
- Locale-specific guidance and a locale-specific model handle can live in `L10N/<locale>.md`.

This lets a repository keep broad voice guidance at the root while placing product-area or language-specific guidance close to the content it affects.