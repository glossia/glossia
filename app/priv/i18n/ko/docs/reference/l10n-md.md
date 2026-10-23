%{
  title: "L10N.md",
  summary: "저장소 번역 설정 및 컨텍스트 참조.",
  category: "참조",
  section: "translation",
  order: 1
}
---

`L10N.md` 는 Glossia 가 어떤 파일을 번역할지, 번역된 파일이 어디에 속하는지, 어떤 언어를 대상으로 하여야 하는지, 그리고 결과를 안내할 컨텍스트가 무엇인지 알려줍니다. 저장소는 루트 파일과 서브디렉토리의 추가된 스코프 파일로 구성될 수 있습니다.

## ## 구조

각 파일에는 두 가지 부분이 있습니다:

1. `---` 마커 사이에 있는 [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 프론트마터입니다.
2. 프론트마터 아래에는 제품, 청중, 목소리, 또는 도메인 컨텍스트가 포함된 마크다운이 있습니다.

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

제공자 자격 증명은 계정 설정에 있어야 하며 절대 `L10N.md` 에는 포함되지 않습니다. 선택 사항인 `model` 값은 계정 모델 핸들입니다.

## 프론트마터 필드

| 필드 | 입력 유형 | 필요 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아님 | 이 영역의 소스 로케일입니다. 기본값은 `en` 입니다. |
| `model` | 문자열 | 아님 | 계정 모델 핸들입니다. 생략될 경우GLOSSIA 는 계정 기본값을 사용하고, 명시된 핸들이 존재하지 않는 경우 오류를 보고합니다. |
| `sources` | 맵 또는 목록 | 최상위 규칙을 위한 | 소스 파일 패턴입니다. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 목록 | 소스가 구성되었을 경우 | 대상 로케일 코드입니다. 맵은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑이 없거나 `target_path` 이 목적지를 제공하는 경우 | 출력 파일 템플릿. |
| `target_path` | 문자열 | 소스 매핑이 없거나 `output` 이 목적지를 제공하는 경우 | 번역 파일의 기본 디렉토리 템플릿입니다. |
| `translate` | 목록 | 아님 | 여러 번역 규칙으로, 각각 고유한 소스와 선택적 오버라이드를 포함합니다. |
| `exclude` | 목록 | 아님 | 제외할 파일 패턴입니다. |
| `preserve` | 목록 | 아님 | 변경되지 않아야 하는 콘텐츠 종류, 예: 플레이스홀더 또는 URI 입니다. |
| `frontmatter` | 문자열 | 아님 | `preserve` 에 기본값 또는 `translate` 입니다. |
| `prompt` | 문자열 | 아님 | 이 영역 또는 규칙에 대한 추가 안내입니다. |
| `validation` | 목록 | 내장 어댑터가 없는 파일 확장자에 대한 | 검증 명령과 해당 인자가 따릅니다. 이 명령은 파일이 실제 타겟 경로에 있고, 파일이 유효하지 않은 경우 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 아님 | 번역 워크플로우에서 사용할 수 있는 체크 명령입니다. |
| `check_cmds` | 맵 | 아님 | 번역 워크플로우에서 사용할 수 있는 지정된 체크 명령입니다. |
| `retries` | 정수 | 아님 | 실패한 체크 후 재시도 횟수입니다. 기본값은 `2` 입니다. |
| `locale` | 문자열 | 아님 | 로케일별 컨텍스트 파일에 첨부되는 로케일입니다. |
| `glossary` | 목록 또는 맵 | 아님 | `L10N.md` 에서는 용어 목록입니다. `L10N/<locale>.md` 에서는 해당 언어별 각 용어에서 그 번역으로 가는 맵입니다. 중첩 파일은 상속된 항목에 추가하고 이를 오버라이드합니다. [사전 참조](/docs/reference/glossary) 를 참조하세요. |

알 수 없는 프론트마터 필드는 무시됩니다.

## 파일 형식

Glossia 는 마크다운, JavaScript 객체 구분 기호, YAML 은 마크업 언어가 아닙니다, 휴대용 객체, 및 일반 텍스트 파일에 대해 기본 처리를 제공합니다. 다른 파일 확장자는 적용 가능한 `L10N.md` 에서 `validation` 명령을 선언하지 않는 한 계획이 실패합니다. 이는 독점 구조 형식을 제한되지 않는 텍스트로 침묵적으로 처리하는 것을 방지합니다.

마크다운에서는 서사만 번역됩니다: 단락, 제목, 목록 항목, 표 셀, 컴포넌트 및 HTML 의 `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, 및 `caption` 속성, 그리고 HTML `<summary>` 의 텍스트입니다. 코드, 링크 대상, 컴포넌트, 경고, 및 명시적 제목 앵커를 포함한 모든 다른 바이트는 소스 그대로 유지됩니다. [번역 복구](/docs/explanation/translation-recovery) 가 어떻게 작동하는지 참조하세요.

검증 명령은 후보가 실제 타겟 경로에 일시적으로 작성된 후 실행됩니다. 이 명령은 저장소의 내부 파서, 컴파일러 또는 빌드 명령을 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 타겟을 복구한 후에만 된 후보를 작성합니다.

## 소스 매핑

가장 명확한 형태는 모든 소스 패턴을 출력 템플릿에 매핑하는 것:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록도 유효하지만, `output` 또는 `target_path` 를 사용하여 목적지를 정의해야 합니다:

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
| `{relpath}` | 맞은 패턴에 대한 상대 소스 경로. |
| `{basename}` | 확장자 없는 소스 파일명. |
| `{ext}` | 선두 점이 없는 소스 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹이 서로 다른 목적지나 검사를 필요로 할 때는 `translate` 을 사용하세요:

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

Glossia 는 `L10N.md` 파일을 저장소 루트에서 소스 파일 방향으로 읽습니다:

- 상위 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉터리의 필드를 오버라이드합니다.
- markdown 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 안내 및 로케일별 모델 핸들은 `L10N/<locale>.md` 에 위치할 수 있습니다.

이를 통해 저장소는 루트에 광범위한 목소리 지침을 유지하면서, 제품 영역 또는 로케일별 지침을 그 콘텐츠가 영향을 미치는 곳에서 가까이 배치할 수 있습니다.
