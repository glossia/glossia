%{
  title: "L10N.md",
  summary: "저장소 번역 설정 및 맥락에 대한 참조.",
  category: "참조",
  section: "translation",
  order: 1
}
---
`L10N.md` Glossia 에는 번역할 파일을 지정하고, 번역된 파일이 저장되는 위치, 대상 언어를 설정하며, 결과에 도움이 되는 컨텍스트를 안내합니다. 저장소는 루트 파일과 서브디렉토리에 추가된 파일이 있을 수 있습니다.

## 구조

각 파일은 두 가지 구성 요소로 이루어집니다:

1. [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 마커 사이에 위치한 프론트머디 `---` 마커.
2. 프론트머디 아래에는 제품, 대상 독자, 어조, 또는 도메인 컨텍스트가 포함된 마크다운이 있습니다.

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

제공자 자격증명은 계정 설정에 있어야 하며, 절대 해당 위치 내부에 포함되지 않아야 합니다 `L10N.md`. 선택 사항 `model` 값은 계정 모델 핸들입니다.

## 프론트매터 필드

| 필드 | 유형 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아님 | 해당 범위의 기본 로케일입니다. 기본 로케일로 설정되 `en`. |
| `model` | string | no | 계정 모델 핸들. Glossia 는 생략될 경우 계정 기본값을 사용하고 명시적인 핸들이 존재하지 않으면 오류를 보고합니다. |
| `sources` | map or list | 최상위 규칙일 경우 | 소스 파일 패턴. Map 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | map or list | 소스가 설정된 경우 | 대상 로케일 코드. Map 은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | string | 소스 매핑이 없는 경우 또는 `target_path` 목적지를 제공합니다 | 출력 파일 템플릿. |
| `target_path` | string | 출처 매핑이 없거나 `output` 목적지를 제공합니다 | 번역된 파일의 기본 디렉터리 템플릿. |
| `translate` | list | no | 여러 변환 규칙, 각각 고유한 출처 및 선택적 오버라이드. |
| `exclude` | list | no | 제외할 파일 패턴. |
| `preserve` | list | no | 변경하지 않고 유지해야 하는 콘텐츠의 종류입니다. 예를 들어 플레이스홀더 또는 URI 와 같습니다. |
| `frontmatter` | string | no | `preserve` 기본적으로 또는 `translate`. |
| `prompt` | string | no | 해당 범위 또는 규칙에 대한 추가 안내입니다. |
| `validation` | 목록 | 내장 어댑터가 없는 파일 확장자를 위한 | 인수를 포함한 검증 명령입니다. 명령은 실제 대상 경로에서 후보를 받으며, 파일이 유효하지 않은 경우 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 아님 | 번역 워크플로우에 사용 가능한 확인 명령입니다. |
| `check_cmds` | 맵 | 아님 | 번역 워크플로우에 사용 가능한 이름 지정된 확인 명령입니다. |
| `retries` | 정수 | 아님 | 실패한 확인 후 재시도 횟수입니다. 기본값은 `2`. |
| `locale` | string | no | 지역별 컨텍스트 파일에 연결된 로케일. |
| `glossary` | 목록 또는 맵 | no | 다음 `L10N.md`, 사전 용어 목록. 다음 `L10N/<locale>.md`, 해당 용어 번역을 매핑하는 맵. 중첩된 파일은 상속 항목을 추가하고 덮어씀. 확인하여 [사전 참조](/docs/reference/glossary). |

알려지지 않은 프론트머트 필드는 무시됩니다.

## 파일 형식

Glossia 는 Markdown, 자바스크립트 객체 표기법, YAML Ain't Markup Language, portable object, 및 평문 텍스트 파일에 대한 내장 처리를 제공합니다. 다른 파일 확장자는 계획 수립에 실패하며, 적용 가능한 `L10N.md` 명령을 선언하는 `validation` 명령입니다. 이는 전용 구조 형식을 제한 없는 텍스트로 침묵적으로 취급하지 않도록 방지합니다.

검증 명령은 후보자가 실제 타겟 경로에 임시로 작성된 후 실행됩니다. 레포지토리의 네이티브 파서, 컴파일러 또는 빌드 명령을 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 타겟을 복원하며 승인된 후보자만 작성합니다.

## 원본 매핑

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿에 매핑합니다:

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