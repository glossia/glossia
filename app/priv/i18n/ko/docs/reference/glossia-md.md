%{title: "GLOSSIA.md", summary: "저장소 번역 설정 및 컨텍스트에 대한 참조.", category: "참조", order: 1}
---
`GLOSSIA.md` 는 Glossia 가 번역할 파일, 번역된 파일의 위치, 대상으로 설정할 언어 및 결과에 대한 컨텍스트를 결정하는 역할을 합니다. 저장소에는 루트 파일과 서브디렉토리에 추가된 스코프 지정 파일이 있을 수 있습니다.

## 구조

각 파일에는 두部分组成 됩니다:

1. [YAML Ain't Markup Language](https://yaml.org/) `---` 마커 사이의 프론트마터.
2. 프론트마터 아래에 있는 마크다운, 제품, 청중, 또는 도메인 컨텍스트.

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

제공자 자격 증명은 계정 설정에 있어야 하며 절대 `GLOSSIA.md` 에 포함되면 안 됩니다. 선택적 `model` 값은 계정 모델 핸들입니다.

## 프론트마터 필드

| 필드 | 유형 | 필요 여부 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아님 | 이 범위의 소스 로케일. 기본값은 `en`입니다. |
| `model` | 문자열 | 아님 | 계정 모델 핸들. 생략 시에는 Glossia 가 계정 기본값을 사용하며 명시된 핸들이 존재하지 않으면 오류를 보고합니다. |
| `sources` | 맵 또는 목록 | 최상위 규칙을 위한 것 | 소스 파일 패턴. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 목록 | 소스가 구성되었을 때 | 대상 로케일 코드. 맵은 로케일 코드와 언어 이름을 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑 또는 `target_path` 가 목적지를 제공하는 경우 없음 | 출력 파일 템플릿. |
| `target_path` | 문자열 | 소스 매핑 또는 `output` 이 목적지를 제공하는 경우 없음 | 번역된 파일의 기본 디렉터리 템플릿. |
| `translate` | 목록 | 아님 | 각 자체 소스와 추가 가능한 오버라이드가 있는 여러 번역 규칙. |
| `exclude` | 목록 | 아님 | 건너뛰어야 하는 파일 패턴. |
| `preserve` | 목록 | 아님 | 변경되지 않아야 하는 콘텐츠 종류, 예: 플레이스홀더 또는 uniform resource locators 기. |
| `frontmatter` | 문자열 | 아님 | 기본값은 `preserve` 또는 `translate`. |
| `prompt` | 문자열 | 아님 | 이 범위 또는 규칙에 대한 추가 안내. |
| `validation` | 목록 | 내장 어댑터가 없는 파일 확장자를 위한 것 | 명령과 해당 인자를 검증 명령. 명령은 실제 목표 경로에서 후보를 수신하며 파일이 유효하지 않을 때 0 이 아닌 상태를 반환해야 합니다. |
| `check_cmd` | 문자열 | 아님 | 번역 워크플로우에서 사용할 수 있는 확인 명령. |
| `check_cmds` | 맵 | 아님 | 번역 워크플로우에서 사용할 수 있는 이름 지정 확인 명령. |
| `retries` | 정수 | 아님 | 실패한 확인 후 재시도 횟수. 기본값은 `2`입니다. |
| `locale` | 문자열 | 아님 | 언어별 컨텍스트 파일에 연결된 로케일. |

알 수 없는 프론트마터 필드는 무시됩니다.

## 파일 형식

Glossia 는 마크다운, JavaScript 객체 표기법 (JSON), YAML Ain't Markup Language, 이식형 객체, 및 일반 텍스트 파일에 대해 기본 처리 처리를 제공합니다. 적용 가능한 `GLOSSIA.md` 가 `validation` 명령어를 선언하지 않는 한 기타 파일 확장자는 계획 전에 실패합니다. 이는 전용 구조화된 형식을 제약 없는 텍스트로 침묵 없이 처리하는 것을 방지합니다.

검증 명령어는 후보가 실제 대상 경로로 임시로 작성된 후 실행됩니다. 그것은 저장소의 네이티브 파서, 컴파일러, 또는 빌드 명령어를 호출할 수 있습니다. Glossia 는 각 검증 시도 후 이전 목표를 복원하며, 이후에만 승인된 후보를 작성합니다.

## 소스 매핑

가장 명확한 형식은 모든 소스 패턴을 출력 템플릿에 매핑하는 것입니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록 또한 유효하지만, 목적지를 정의하려면 `output` 또는 `target_path`가 필요합니다.

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 목표 언어

리스트는 각 로케일 코드를 언어 식별자로 사용합니다:

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
| `{locale}` 또는 `{lang}` | 목표 로케일 코드입니다. |
| `{relpath}` | 일치된 패턴에 상대인 소스 경로입니다. |
| `{basename}` | 확장자 없는 소스 파일명입니다. |
| `{ext}` | 이끄는 마침표 없는 소스 파일 확장입니다. |

## 여러 규칙

사용`translate` 다른 콘텐츠 그룹이 다른 목적지나 검사를 필요로 할 때:

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

## 범위 지정 컨텍스트

GLOSSIA 는`GLOSSIA.md` 파일을 저장소 루트에서 소스 파일로 이동하며 읽습니다:

- 부모 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉터리의 필드를 덮어씁니다.
- 마크다운 컨텍스트는 부모에서 자식으로 누적됩니다.
- 로케일별 지침과 로케일별 모델 핸들은`GLOSSIA/<locale>.md` 에 배치할 수 있습니다.

이를 통해 저장소는 넓은 목소리 지침을 루트에서 유지하면서 제품 영역 또는 로케일별 지침을该内容에 영향이 미치는 위치에 배치할 수 있습니다.