%{title: "L10N.md", summary: "저장소 번역 설정 및 맥락에 대한 참조.", category: "참조", order: 1}
---
`L10N.md` 글로시아에게 어떤 파일을 번역할지, 번역된 파일이 어디에 위치할지, 표적 언어는 무엇인지, 그리고 결과에 참고될 컨텍스트는 무엇인지 알려줍니다. 저장소에는 루트 파일과 서브 디렉토리에 추가된 스코프 파일이 있을 수 있습니다.

## 구조

각 파일은 두 부분으로 구성됩니다:

1. [YAML 은 마크업 언어가 아닙니다](https://yaml.org/) 마커 사이의 프론트매터 `---` 마커입니다.
2. 프론트매터 아래에 있으며 제품, 청중, 음성 또는 도메인 컨텍스트를 포함한 Markdown

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

제공자 자격 증명은 계정 설정에만 있어야 하며 절대에는 `L10N.md`. 선택 사항 `model` 값은 계정 모델 핸들입니다.

## 프론트매터 필드

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | string | no | 이 범위의 소스 로케일입니다. 기본값은 `en`. |
| `model` | 문자열 | no | 계정 모델 핸들. Glossia 는 생략되었을 때 기본 계정을 사용하며 명시적인 핸들이 존재하지 않을 때 오류를 보고합니다. |
| `sources` | 맵 또는 목록 | 상위 규칙을 위한 | 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 목록 | 소스가 구성되었을 때 | 대상 로케일 코드. 맵은 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑이 없는 경우 또는 `target_path` 출력 위치를 지정합니다 | 출력 파일 템플릿입니다. |
| `target_path` | 문자열 | 소스 매핑이 없을 경우 또는 `output` 출력 위치를 지정합니다 | 번역된 파일의 기본 디렉터리 템플릿입니다. |
| `translate` | 목록 | 없음 | 여러 번역 규칙, 각각 고유한 소스와 선택적 오버라이드를 포함합니다. |
| `exclude` | 목록 | 없음 | 건너뛰려는 파일 패턴입니다. |
| `preserve` | list | no | 변경되지 않아야 하는 콘텐츠의 종류, 예: 자리표시자 또는 유니폼 리소스 로케이터. |
| `frontmatter` | string | no | `preserve` 기본값으로, 또는 `translate`. |
| `prompt` | string | no | 이 범주 또는 규칙에 대한 추가 지침.
| `validation` | list | 내장 어댑터가 없는 파일 확장자를 위한 | 검증 명령에 이어진 인수들. 명령은 후보를 실제 대상 경로에서 수신하며 파일이 유효하지 않을 때 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | string | 아니요 | 번역 워크플로우에 사용할 수 있는 확인 명령입니다. |
| `check_cmds` | map | 아니요 | 번역 워크플로우에 사용할 수 있는 명명된 확인 명령들입니다. |
| `retries` | integer | 아니요 | 실패한 확인 후 재시도 시도 횟수. 기본값은 `2`. |
| `locale` | 문자열 | 아니요 | 로케일 특화 컨텍스트 파일에 연결된 로케일. |

알 수 없는 프론트마터 필드는 무시됩니다.

## 파일 형식

Glossia 는 마크다운, 자바스크립트 객체 표기 (JSON), 'YAML 은 마크업이 아닙니다', 포터블 오브젝트 및 일반 텍스트 파일에 대해 내장 처리를 지원합니다. 기타 파일 확장자는 적용 가능한 `L10N.md` 선언하는 `validation` 명령. 이는 고유한 구조화된 형식을 제한되지 않은 텍스트로 묵시적으로 처리하는 것을 방지합니다.

검증 명령은 실제 대상 경로에 후보자가 임시로 작성된 후 실행됩니다. 이는 저장소의 네이티브 파서, 컴파일러, 또는 빌드 명령을 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 대상으로 복원하며, 승인된 후보자 이후에만 작성합니다.

## 소스 매핑

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿에 매핑합니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록 또한 유효하지만 정의하려면 `output` 또는 `target_path` 대상을 정의합니다:

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
| `{relpath}` | 일치한 패턴에 대한 소스 경로. |
| `{basename}` | 확장자를 제외한 소스 파일명. |
| `{ext}` | 앞의 점 없는 소스 파일 확장자. |

## 여러 규칙

다른 콘텐츠 그룹이 다른 경로나 검사가 필요한 경우 `translate` 를 사용하세요:

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

규칙의 값은 주변 파일에서 상속된 값보다 우선합니다.

## 범위 지정 컨텍스트

Glossia 는 저장소 루트에서 소스 파일로 향하는 `L10N.md` 파일을 읽습니다:

- 상위 설정이 기본값을 제공합니다.
- 더 깊은 파일이 해당 디렉터리의 필드를 덮어씁니다.
- 마크다운 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 가이드 및 로케일별 모델 핸들은 `L10N/<locale>.md` 에 저장될 수 있습니다.

이는 저장소 루트에는 광범위한 목소리 가이드를 유지하면서 제품 영역별 또는 언어별 가이드는该内容에 가까이 배치할 수 있도록 합니다.