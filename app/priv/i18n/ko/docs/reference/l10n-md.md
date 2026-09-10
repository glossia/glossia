%{title: "L10N.md", summary: "저장소 번역 설정 및 컨텍스트에 대한 참고 문서.", category: "참고", order: 1}
---
`L10N.md` 는 Glossia 에 번역할 파일을 지정하고, 번역된 파일의 위치, 타겟 언어, 그리고 결과의 안내를 위한 컨텍스트를 제공합니다. 레포지토리는 루트 파일과 서브디렉터리 내의 추가 스코프 파일을 가질 수 있습니다.

## 구조

각 파일에는 두 가지部分组成이 있습니다:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter Between `---` 마커.
2. 프론트마터 아래의 마크다운은 제품, 청자, 톤, 또는 도메인 컨텍스트.

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

제공자 자격 증명은 계정 설정에 positioned 되어야 하며, 절대 `L10N.md` 는 포함될 수 없습니다. 선택 사항인 `model` 값은 계정 모델 핸들입니다.

## 프론트마터 필드

| 필드 | 형식 | 필수 | 설명 |
|---|---|---|---|
| `source_language` | string | no | 이 스코프의 소스 로케일입니다. 기본값은 `en` 입니다. |
| `model` | string | no | 계정 모델 핸들입니다. 제외된 경우 기본값이 사용되며 명시된 핸들이 존재하지 않으면 오류가 표시됩니다. |
| `sources` | map or list | top-level root | 원본 파일 패턴입니다. 맵 값은 출력 템플릿을 정의할 수 있습니다. |
| `targets` | map or list | when sources are configured | 타겟 로케일 코드입니다. 맵은 로케일 코드와 언어 이름을 관계할 수 있습니다. |
| `output` | string | when no source mapping or `target_path` supplies a destination | 출력 파일 템플릿입니다. |
| `target_path` | string | when no source mapping or `output` supplies a destination | 번역 파일의 기본 디렉터리 템플릿입니다. |
| `translate` | list | no | 각 소스가 있는 다중 번역 규칙 또는 선택 지시사항이 있습니다. |
| `exclude` | list | no |跳过一个ık.pattern 파일 패턴입니다. |
| `preserve` | list | no | 무손실 처리해야 하는 내용을 지정합니다. 예: placeholders,\_uniform resource locators. |
| `frontmatter` | string | no | `preserve` 기본값 또는 `translate`. |
| `prompt` | string | no | 이 스κο프 또는 규칙에 대한 추가 지침입니다. |
| `validation` | list | file extensions without a built-in adapter | 검증 명령어와 그 인수입니다. 명령어는 실제 타겟 경로에서 후보를 받으며 파일이 무효일 때 비영리 estatstatus 를 반환해야 합니다. |
| `check_cmd` | string | no | 번역 워크플로우에 사용할 수 있는 검사 명령어입니다. |
| `check_cmds` | map | no | 번역 워크플로우에 사용할 수 있는 명명한 검사 명령어입니다. |
| `retries` | integer | no | 실패한 검사 후 재시도 횟수입니다. 기본값은 `2` 입니다. |
| `locale` | string | no | 로케일에 특화된 컨텍스트 파일에 첨부된 로케일입니다. |

알 수 없는 프론트마터 필드는 무시됩니다.

## 파일 형식

Glossia 는 마크다운, JavaScript Object Notation, YAML Ain't Markup Language, 가용식 객체, 및 순수 텍스트 파일에 대해 기본 처리 코드를 가지고 있습니다. 적용 가능한 `L10N.md` 에서 `validation` 명령을 선언하지 않는 한 다른 파일 확장자는 계획 수립에 실패합니다. 이는 특수 구조화된 형식을 제한하지 않은 텍스트로 조용히 취급하는 것을 피하는 것입니다.

검증 명령은 후보가 실제 목표 경로에 임시로 기록된 후 실행됩니다. 레포지토리의 네이티브 파서, 컴파일러, 또는 빌드 명령어 호출을 할 수 있습니다. Glossia 는 각 검증 시도가 허용되면 이전 목적지를 복원하며 온전히 승인된 후보만 이후에 작성합니다.

## 소스 매핑

가장 명확한 방법은 각 소스 패턴을 출력 템플릿으로 매핑하는 것입니다:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록 또한 유효하지만, 목적지를 정의하려면 `output` 또는 `target_path` 가 필요합니다:

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
| `{relpath}` | 일치된 패턴에 대한 소스 경로. |
| `{basename}` | 확장자 제외 소스 파일명. |
| `{ext}` | 점 앞 제외 소스 파일 확장자. |

## 다중 규칙

사용 `translate` 다른 콘텐츠 그룹이 서로 다른 대상 또는 검사를 필요로 하는 경우:

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

Glossia 가 읽습니다 `L10N.md` 파일을 저장소 루트에서 소스 파일 쪽으로:

- 상위 설정은 기본값을 제공합니다.
- 더 깊은 파일은 해당 디렉토리의 필드를 덮어씁니다.
- 마크다운 컨텍스트는 부모에서 자식으로 축적됩니다.
- 로케일별 가이드와 로케일별 모델 핸들은 ...에 존재할 수 있습니다. `L10N/<locale>.md`.

이는 레포지토리가 루트에 광범위한 음성 가이드를 유지하면서도 제품 영역이나 언어별 가이드를 해당 콘텐츠에 가까이 배치할 수 있게 합니다.