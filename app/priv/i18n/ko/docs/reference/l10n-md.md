%{title: "L10N.md", summary: "저장소 번역 설정 및 컨텍스트 참조.", category: "reference", order: 1}
---
`L10N.md` Glossia 에 번역할 파일, 번역된 파일의 위치, 대상 언어 및 결과 안내에 필요한 컨텍스트가 무엇인지 안내합니다. 리포지토리는 루트 파일과 서브디렉터리에서 추가된 범위가 지정된 파일을 가질 수 있습니다.

## 구조

각 파일은 두 가지 구성 요소로 이루어져 있습니다:

1. [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 프론트매터는 마커 사이 `---` 마커입니다.
2. 프론트매터 하단의 마크다운에는 제품, 대상, 목소리 또는 도메인 컨텍스트가 포함되어 있습니다.

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

제공자 자격증명은 계정 설정에 있어야 하며, 절대 `L10N.md`. 선택 사항 `model` 값은 계정 모델 핸들입니다.

## 프론트매터 필드

| 필드 | 유형 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아니요 | 이 범위의 원본 로케일입니다. 기본값은 `en`|
| `model` | 문자열 | 선택 | 계정 모델 핸들. Glossia 는 생략될 경우 기본 계정을 사용하고 명시적인 핸들이 존재하지 않으면 오류를 보고합니다. |
| `sources` | 맵 또는 리스트 | 상위 규칙용 | 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 리스트 | 소스가 설정된 경우 | 대상 로케일 코드. 맵은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑이 없을 때 또는 `target_path` 목적지를 제공합니다 | 출력 파일 템플릿. |
| `target_path` | 문자열 | 소스 매핑이 없거나 `output` 목적지를 제공합니다 | 번역된 파일용 기본 디렉터리 템플릿. |
| `translate` | 목록 | 없음 | 각자의 고유한 소스 및 선택적 오버라이드를 가진 여러 번역 규칙. |
| `exclude` | 목록 | 없음 | 제외할 파일 패턴. |
| `preserve` | list | no | 변경하지 않아야 하는 콘텐츠 종류, 예를 들어 플레이스홀더 또는 유니폼 리소스 로케이터입니다. |
| `frontmatter` | string | no | `preserve` 기본적으로, 또는 `translate`. |
| `prompt` | string | no | 이 범위 또는 규칙에 대한 추가 지침입니다. |
| `validation` | 리스트 | 내장된 어댑터가 없는 파일 확장자를 위한 | 유효성 검사 명령 및 해당 인수입니다. 명령은 실제 타겟 경로에서 후보를 받으며, 파일이 무효인 경우 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 없음 | 번역 워크플로우에 사용할 수 있는 검증 명령입니다. |
| `check_cmds` | 맵 | 없음 | 번역 워크플로우에 사용할 수 있는 이름이 지정된 검증 명령입니다. |
| `retries` | 정수 | 없음 | 검증 실패 후 재시도 횟수입니다. 기본값은 `2`. |
| `locale` locale별 컨텍스트 파일에 연결된 로케일입니다.

알 수 없는 프론트매터 필드는 무시됩니다.

## 파일 형식

Glossia 는 Markdown, 자바스크립트 객체 표기법, YAML Ain't Markup Language, Portable Object, 및 일반 텍스트 파일에 대해 내장 처리를 제공합니다. 다른 파일 확장자는 계획 수립에 실패하며, 적용 가능한 `L10N.md` 선언하는 `validation` 명령. 이는 전용 구조화된 형식을 제약 없는 텍스트로 조용하게 처리하는 것을 방지합니다.

검증 명령어는 후보를 실제 대상 경로에 임시로 작성한 후 실행됩니다. 저장소의 네이티브 파저, 컴파일러 또는 빌드 명령어를 호출할 수 있으며, Glossia 는 각 검증 시도 후 이전 대상 경로를 복원하고 승인된 후보만 작성합니다.

## 소스 매핑

가장 명확한 형태는 모든 소스 패턴을 출력 템플릿에 매핑합니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록도 유효하지만 다음이 필요합니다 `output` 또는 `target_path` 목적지를 정의합니다:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 대상 언어

표는 각 로케일 코드를 언어 식별자로 사용합니다:

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
| `{locale}` or `{lang}` | 대상 로케일 코드. |
| `{relpath}` | 일치한 패턴에 대한 상대 경로. |
| `{basename}` | 확장자를 제거한 원본 파일 이름. |
| `{ext}` | 앞의 점 없이 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹이 다른 위치나 확인이 필요할 때 `translate` 를 사용하세요:

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

## 범주화된 컨텍스트

Glossia 는 저장소 루트에서 소스 파일로 향하여 `L10N.md` 파일을 읽습니다:

- 상위 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉터리의 필드를 덮어씁니다.
- 마크다운 컨텍스트는 상에서 아래로 누적됩니다.
- 로케일별 지침과 로케일별 모델 핸들은 `L10N/<locale>.md` 에 배치할 수 있습니다.

이는 저장소가 루트에 광범위한 목소리 지침을 유지하면서 제품 영역별 또는 언어별 지침을 해당 콘텐츠 근처에 배치할 수 있게 합니다.