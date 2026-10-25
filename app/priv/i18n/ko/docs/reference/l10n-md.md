%{
  title: "L10N.md",
  summary: "레포지토리 번역 설정 및 컨텍스트에 대한 참고.",
  category: "참고",
  section: "translation",
  order: 1
}
---

`L10N.md` 는 Glossia 가 어떤 파일을 번역할지, 번역된 파일이 어디에 위치할지, 표적 언어는 무엇인지, 그리고 결과를 안내할 컨텍스트를 지정합니다. 저장소에는 루트 파일과 서브디렉터리에 추가된 스코프 파일이 있을 수 있습니다.

## 구조

각 파일에는 두 부분이 있습니다:

1. [YAML 은 마크업이 아닙니다](https://yaml.org/) 프론트마터는 `---` 마커 사이로 배치됩니다.
2. 프론트마터 아래의 마크다운에는 제품, 대상 청중, 목소리 또는 도메인 컨텍스트가 명시됩니다.

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

제공자 인증정보는 계정 설정에 위치해야 하며 절대 `L10N.md` 에 들어가지는 않습니다. 선택 사항인 `model` 값은 계정 모델 핸들입니다.

## 프론트마터 필드

| 필드 | 형식 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아니요 | 이 스코프의 소스 로케일입니다. 기본값은 `en` 입니다. |
| `model` | 문자열 | 아니요 | 계정 모델 핸들입니다. 생략하면 Glossia 는 기본값을 사용하며 명시적인 핸들에 해당하지 않을 경우 오류를 보고합니다. |
| `sources` | 맵 또는 리스트 | 최상위 규칙의 경우 | 소스 파일 패턴입니다. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 리스트 | 소스가 구성된 경우 | 표적 로케일 코드입니다. 맵은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑이나 `target_path` 이 목적지를 제공하는 경우 | 출력 파일 템플릿. |
| `target_path` | 문자열 | 소스 매핑이나 `output` 이 목적지를 제공하는 경우 | 번역 파일의 기본 디렉터리 템플릿. |
| `translate` | 리스트 | 아니요 | 여러 번역 규칙입니다. 각 규칙에는 고유한 소스와 선택적인 오버라이드가 있습니다. |
| `exclude` | 리스트 | 아니요 | 스캔할 파일 패턴. |
| `preserve` | 리스트 | 아니요 | 변경하지 않고 그대로 유지되어야 하는 콘텐츠 유형, 예를 들어 플레이스홀더 또는 일관된 리소스 식별자입니다. |
| `frontmatter` | 문자열 | 아니요 | 기본값은 `preserve` 이거나 `translate` 입니다. |
| `prompt` | 문자열 | 아니요 | 이 스코프나 규칙에 대한 추가 안내. |
| `validation` | 리스트 | 고유 아다프터가 없는 파일 확장자의 경우 | 검증 명령 뒤에 해당 인자가 따릅니다. 명령은 실제 목표 경로에서 후보를 받으며 파일이 무효인 경우 nonzero 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 아니요 | 번역 워크플로우에서 사용할 수 있는 검사 명령. |
| `check_cmds` | 맵 | 아니요 | 번역 워크플로우에서 사용할 수 있는 이름이 있는 검사 명령. |
| `retries` | 정수 | 아니요 | 검사 실패 후 다시 시도할 횟수입니다. 기본값은 `2`. |
| `locale` | 문자열 | 아니요 | 로케일별 컨텍스트 파일에 연결된 로케일. |
| `glossary` | 리스트 또는 맵 | 아니요 | `L10N.md` 에서는 사전 용어들 lists 입니다. `L10N/<locale>.md` 에서는 각 용어에서 해당 언어 번역으로의 맵입니다. 중첩된 파일은 상속된 항목을 추가하고 오버라이드합니다. [사전 참조](/docs/reference/glossary)를 확인하세요. |

알 수 없는 프론트마터 필드는 무시됩니다.

## 파일 형식

Glossia 는 마크다운, JavaScript Object Notation, YAML Ain't Markup Language, 순서 가능한 객체, 및 일반 텍스트 파일에 대해 기본 처리를 지원합니다. 적용할 `L10N.md` 이 `validation` 명령을 선언하지 않는 한 다른 파일 확장자는 플래닝에 실패합니다. 이는 특수 구조 형식을 제약 처리 없이 문백으로 처리한다고 여겨 상것하지 않게 막아줍니다.

마크다운에서는 오직 정문만 번역됩니다: 단락, 제목, 리스트 항목, 표 셀, 컴포넌트와 HTML 의 `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, 및 `caption` 속성, 및 HTML `<summary>` 의 텍스트. 코드, 링크 목적지, 컴포넌트, 경고 및 명시적인 제목 앵커를 포함한 모든 다른 바이트는 소스와 정확히 같습니다. [번역 복구](/docs/explanation/translation-recovery) 에서 이 방식이 작동하는 방법을 확인하세요.

검증 명령은 후보가 실제 목표 경로에 임시로 쓰여진 후에 실행됩니다. 리포지토리의 네이티브 파서, 컴파일러, 또는 빌드 명령을 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 목표를 복원하며 승인된 후보 만 이후에 씁니다.

## 소스 매핑

가장 명확한 형식은 각 소스 패턴을 출력 템플릿에 매핑합니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 리스트 또한 유효하지만, 목적지를 정의하려면 `output` 또는 `target_path` 가 필요합니다:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 표적 언어

리스트는 각 로케일 코드를 언어 식별자로 사용합니다:

```yaml
targets:
  - es
  - ja
```

맵은 읽을 수 있는 언어 이름을 추가할 수 있습니다:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| 변수 | 값 |
|---|---|
| `{locale}` 또는 `{lang}` | 표적 로케일 코드. |
| `{relpath}` | 매칭 패턴에 상대적으로 있는 소스 경로. |
| `{basename}` | 확장자를 제거한 소스 파일명. |
| `{ext}` | 맨 앞 점을 제거한 소스 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹이 서로 다른 목적지나 검증이 필요할 때 `translate` 를 사용:

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

규칙 값은 주변 파일에서 상속된 값을 오버라이드합니다.

## 범위별 컨텍스트

Glossia 는 리포지토리의 루트에서 소스 파일 쪽으로 `L10N.md` 파일을 읽습니다:

- 부모 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉터리의 필드를 오버라이드합니다.
- 마크다운 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 가이드라인과 로케일별 모델 핸들은 `L10N/<locale>.md` 안에 있을 수 있습니다.

이 구조는 리포지토리가 루트에서 광범위한 목소리 가이드라인을 유지하면서 제품 영역이나 언어별 가이드라인을 해당 콘텐츠에 가까이 배치할 수 있게 합니다.
