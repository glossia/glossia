%{
  title: "L10N.md",
  summary: "레포지토리 번역 설정 및 컨텍스트 참조.",
  category: "참조",
  section: "translation",
  order: 1
}
---
`L10N.md` Glossia 가 번역할 파일, 번역 결과 위치, 대상 언어, 결과를 안내하는 컨텍스트 를 지정합니다. 저장소는 루트 파일과 하위 디렉토리에 있는 추가 파일을 포함할 수 있습니다.

## 구조

각 파일은 두 부분으로 구성됩니다:

1. [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 마커 사이 프론트마터 `---` 마커.
2. 프론트마터 아래에 제품, 대상 독자, 목소리 또는 도메인 컨텍스트 를 포함한 Markdown 입니다.

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

제공자 자격 증명은 계정 설정에 있어야 하며, 절대 `L10N.md`. 선택 사항 `model` 값은 계정 모델 핸들입니다.

## Frontmatter 필드

| 필드 | 유형 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | string | no | 이 스코프의 소스 로케일입니다. 기본값은 `en`. |
| `model` | string | no | 계정 모델 핸들입니다. Glossia 는 생략될 경우 기본 계정 값을 사용하고 명시적인 핸들이 존재하지 않을 경우 오류를 보고합니다. |
| `sources` | map or list | 최상위 규칙용 | 소스 파일 패턴입니다. map 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | map or list | 소스가 구성되어 있을 경우 | 대상 로케일 코드입니다. map 은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | string | 소스 매핑이 없는 경우 또는 `target_path` 목적지를 제공합니다 | 출력 파일 템플릿. |
| `target_path` | string | 소스 매핑이 없을 때 또는 `output` 목적지를 제공합니다 | 번역된 파일의 기본 디렉토리 템플릿. |
| `translate` | list | no | 각자가 고유한 소스와 선택적 재정의를 가진 여러 개의 번역 규칙. |
| `exclude` | list | no | 제외할 파일 패턴. |
| `preserve` | list | no | 변경 없이 유지해야 하는 콘텐츠 유형, 예를 들어 플레이스홀더 또는 유니폼 리소스 로케이터. |
| `frontmatter` | string | no | `preserve` 기본값으로 또는 `translate`. |
| `prompt` | string | no | 해당 범위 또는 규칙에 대한 추가 지침. |
| `validation` | 리스트 | 내장 어댑터가 없는 파일 확장자용 | 유효성 검사 명령과 인자. 명령은 실제 목표 경로에서 후보를 받으며, 파일이 유효하지 않을 때 0 이 아닌 상태를 반환해야 합니다.
| `check_cmd` | 문자열 | 아니오 | 번역 워크플로우에서 사용할 수 있는 확인 명령.
| `check_cmds` | 맵 | 아니오 | 번역 워크플로우에서 사용할 수 있는 이름 지정 확인 명령.
| `retries` | 정수 | 아니오 | 실패한 확인 후 재시도 횟수. 기본값은 `2`. |
| `locale` | string | 아니요 | 로케일별 컨텍스트 파일에 연결된 로케일입니다. |
| `glossary` | 리스트 또는 맵 | No | In `L10N.md`, 어휘 용어 목록입니다. In `L10N/<locale>.md`, 각 용어에 대한 해당 언어의 번역을 매핑한 맵입니다. 중첩된 파일은 상속 항목을 추가하고 덮어씁니다. 보십시오 [어휘 참조](/docs/reference/glossary). |

알려지지 않은 frontmatter 필드는 무시됩니다.

## 파일 형식

Glossia 는 Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object, 및 plain text 파일을 기본으로 처리합니다. 다른 파일 확장자는 계획에 실패하며, 적용 가능한 경우를 제외하고 `L10N.md` 선언합니다 `validation` 명령입니다. 이는 전용 구조화된 형식을 제약 없는 텍스트로 주지 않게 취급하는 것을 방지합니다.

Markdown 에서, 오직 본문만 번역됩니다: 단락, 제목, 목록 항목, 표 칸, 그 `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, 및 `caption` 컴포넌트 속성 및 HTML, 그리고 HTML 텍스트 `<summary>`. 나머지 바이트는 코드, 링크 목적지, 컴포넌트, 경고 및 명시적 헤딩 앵커를 포함하여 소스에서 정확히 그대로 유지됩니다. 참고하십시오 [번역 복구](/docs/explanation/translation-recovery) 이것이 어떻게 작동하는지입니다.

검증 명령어는 후보자가 실제 대상 경로에 임시로 기록된 후 실행됩니다. 이 명령어는 저장소의 네이티브 파서, 컴파일러, 또는 빌드 명령어를 호출할 수 있습니다. Glossia 는 각 검증 시도 이후 이전 대상 경로를 복원한 후 승인된 후보자만 작성합니다.

## 소스 매핑

가장 명확한 형태는 각 소스 패턴을 출력 템플레이트에 매핑합니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록도 유효하며, 목적지를 정의하려면 `output` 또는 `target_path` 가 필요합니다:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 대상 언어

목록은 각 로케일 설정 코드를 언어 식별자로 사용합니다:

```yaml
targets:
  - es
  - ja
```

맵은 읽기 쉬운 언어 이름을 추가할 수 있습니다:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| 변수 | 값 |
|---|---|
| `{locale}` 또는 `{lang}` | 대상 로케일 코드. |
| `{relpath}` | 일치한 패턴에 대한 상대 경로. |
| `{basename}` | 확장자를 제거한 소스 파일 이름. |
| `{ext}` | 앞의 점 없는 소스 파일 확장자. |

## 다중 규칙

다른 콘텐츠 그룹이 다른 목적지나 검증을 필요로 할 때는 `translate` 를 사용합니다:

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

규칙 값은 주변 파일에서 상속된 값을 덮어씁니다.

## 스코프된 컨텍스트

Glossia 는 저장소 루트에서 소스 파일 방향으로 `L10N.md` 파일을 읽습니다:

- 부모 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉토리의 필드를 덮어씁니다.
- 마크다운 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 가이드와 로케일별 모델 핸들이 `L10N/<locale>.md` 에 위치할 수 있습니다.

이를 통해 저장소는 루트에서 광범위한 목소리 가이드를 유지하면서, 제품 영역별 또는 언어별 지침은 해당 콘텐츠에 가까이 배치할 수 있습니다.