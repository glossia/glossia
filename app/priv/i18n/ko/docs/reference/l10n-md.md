%{
  title: "L10N.md",
  summary: "저장소 번역 설정 및 맥락에 대한 참조.",
  category: "참조",
  section: "translation",
  order: 1
}
---
`L10N.md` 는 Glossia 에 어떤 파일을 번역할지, 번역된 파일이 어디에 속하는지, 어떤 언어를 대상으로 할지, 그리고 어떤 컨텍스트가 결과를 안내해야 하는지 알려줍니다. 저장소에는 루트 파일과 서브디렉토리에 있는 추가 스코프 파일들을 가질 수 있습니다.

## 구조

각 파일은 두 가지 부분으로 구성됩니다:

1. [YAML Ain't Markup Language](https://yaml.org/) 프론트머터 between `---` 마커 사이에 있습니다.
2. 제품, 청중, 목소리 또는 도메인 컨텍스트를 가진 프론트머터 아래의 Markdown.

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

제공자 자격증명은 계정 설정에 있어야 하며, 절대 `L10N.md` 에 포함되어서는 안 됩니다. 옵션인 `model` 값은 사용자 계정 모델 핸들입니다.

## 프론트머터 필드

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | string | no | 이 범위에 대한 소스 로케일. 기본값은 `en`입니다. |
| `model` | string | no | 계정 모델 핸들. 생략 시 Glossia 는 계정 기본값을 사용하고, 명시된 핸들이 존재하지 않으면 에러를 보고합니다. |
| `sources` | map or list | for a top-level rule | 출력 템플릿을 정의할 수 있는 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | map or list | when sources are configured | 대상 로케일 코드. 맵은 로케일 코드와 언어 이름을 연결할 수 있습니다. |
| `output` | string | when no source mapping or `target_path` supplies a destination | 출력 파일 템플릿. |
| `target_path` | string | when no source mapping or `output` supplies a destination | 번역된 파일의 기본 디렉토리 템플릿. |
| `translate` | list | no | 각각의 소스와 가능한 오버라이드가 있는 다수의 번역 규칙. |
| `exclude` | list | no | 스킵할 파일 패턴. |
| `preserve` | list | no | 비변경해야 하는 콘텐츠 종류, 예를 들어 placeholder 나 URI. |
| `frontmatter` | string | no | 기본값은 `preserve` 또는 `translate`. |
| `prompt` | string | no | 이 범위나 규칙에 대한 추가 지침. |
| `validation` | list | for file extensions without a built-in adapter | 내장 어댑터 없이 처리된 파일 확장자에 대한 검증 명령과 인수. 명령이 실제 목표 경로에 있는 후보를 애플리하고 파일이 유효하지 않을 경우 non-zero 상태를 반환해야 합니다. |
| `check_cmd` | string | no | 번역 워크플로우에 사용 가능한 체크 명령. |
| `check_cmds` | map | no | 번역 워크플로우에 사용 가능한 체크 명령. |
| `retries` | integer | no | 실패한 체크 후 재시도 횟수. 기본값은 `2` 입니다. |
| `locale` | string | no | 로케일별 컨텍스트 파일에 연결된 로케일. |
| `glossary` | list or map | no | `L10N.md` 에는 전문용어 목록입니다. `L10N/<locale>.md` 에는 각 용어에 대한 해당 언어 번역 맵입니다. 잠식이 파일들은 상속 항목에 추가하고 오버라이드합니다. [전문용어 참조](/docs/reference/glossary) 확인. |

알려지지 않은 프론트머터 필드는 무시됩니다.

## 파일 형식

Glossia 는 Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object, 그리고 일반 텍스트 파일에 대해 내장 처리 기능을 제공합니다. 적용 가능한 `L10N.md` 에서 `validation` 명령을 명시하지 않는 한 다른 파일 확장자는 계획 단계에서 실패합니다. 이는 독점적인 구조 형식을 제약 없는 텍스트로 조용히 처리하는 것을 방지하기 위함입니다.

검증 명령은 후보가 실제 목표 경로에 일시적으로 작성된 후 실행됩니다. 이 명령은 저장소의 네이티브 파서, 컴파일러 또는 빌드 명령을 호출할 수 있습니다. Glossia 는 각 검증 시도 후에 이전 목표를 복원하며, 검증 통과된 후보만 최종적으로 작성합니다.

## 소스 매핑

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿에 매핑하는 것입니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록도 유효하지만, 목적지를 정의하는 `output` 또는 `target_path` 가 필요합니다.

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

맵은 가독성 높은 언어 이름을 추가할 수 있습니다:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| 변수 | 값 |
|---|---|
| `{locale}` 또는 `{lang}` | 대상 로케일 코드. |
| `{relpath}` | 매칭된 패턴에 대한 상대 경로. |
| `{basename}` | 파일 확장자 없는 소스 파일명. |
| `{ext}` | 앞 점 없는 소스 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹에 destination 이나 검증이 다르다면 `translate` 를 사용하세요:

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

규칙의 값은 주변 파일에서 상속된 값을 덮어씁니다.

## 범위 지정 컨텍스트

Glossia 는 저장소 루트에서 소스 파일로 향하여 `L10N.md` 파일을 읽습니다:

- 부모 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉터리의 필드를 덮어씁니다.
- Markdown 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 가이드라인과 로케일별 모델 핸들은 `L10N/<locale>.md` 에 존재할 수 있습니다.

이를 통해 저장소는 루트에 광범위한 톤 가이드라인을 유지하면서도 해당 콘텐츠에 반영하는 제품 영역 또는 언어별 가이드라인을 그 근처에 배치할 수 있습니다.