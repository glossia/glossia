%{
  title: "GLOSSIA.md",
  summary: "저장소 번역 설정 및 컨텍스트에 대한 참조.",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md`은 Glossia에 번역할 파일, 번역된 파일을 배치할 위치, 대상 언어, 결과에 적용할 맥락을 지정합니다. 저장소에는 루트 파일 하나와 하위 디렉터리에 범위가 지정된 추가 파일이 있을 수 있습니다.

## 구조

각 파일은 두 부분으로 구성됩니다.

1. `---` 마커 사이의 [YAML Ain't Markup Language](https://yaml.org/) 프런트매터
2. 프런트매터 아래에 제품, 대상 독자, 보이스 또는 도메인 맥락을 설명하는 Markdown

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

공급자 자격 증명은 계정 설정에 저장해야 하며, `GLOSSIA.md`에 저장해서는 안 됩니다. 선택 사항인 `model` 값은 계정 모델 핸들입니다.

## 프런트매터 필드

| 필드 | 유형 | 필수 여부 | 설명 |
|---|---|---|---|
| `source_language` | 문자열 | 아니요 | 이 범위의 소스 로케일입니다. 기본값은 `en`입니다. |
| `model` | 문자열 | 아니요 | 계정 모델 핸들입니다. 생략하면 Glossia가 계정 기본값을 사용하며, 명시한 핸들이 존재하지 않으면 오류를 보고합니다. |
| `sources` | 맵 또는 목록 | 최상위 규칙에 필요 | 소스 파일 패턴입니다. 맵 값으로 출력 템플릿을 정의할 수 있습니다. |
| `targets` | 맵 또는 목록 | 소스가 구성된 경우 | 대상 로케일 코드입니다. 맵을 사용하면 로케일 코드를 언어 이름과 연결할 수 있습니다. |
| `output` | 문자열 | 소스 매핑 또는 `target_path`에서 대상을 지정하지 않은 경우 | 출력 파일 템플릿입니다. |
| `target_path` | 문자열 | 소스 매핑 또는 `output`에서 대상을 지정하지 않은 경우 | 번역된 파일의 기본 디렉터리 템플릿입니다. |
| `translate` | 목록 | 아니요 | 각각 자체 소스와 선택적 재정의를 포함하는 여러 번역 규칙입니다. |
| `exclude` | 목록 | 아니요 | 건너뛸 파일 패턴입니다. |
| `preserve` | 목록 | 아니요 | 자리표시자나 통합 자원 위치 지정자처럼 변경하지 않고 유지해야 하는 콘텐츠 유형입니다. |
| `frontmatter` | 문자열 | 아니요 | 기본값은 `preserve`이며, `translate`도 사용할 수 있습니다. |
| `prompt` | 문자열 | 아니요 | 이 범위 또는 규칙에 대한 추가 지침입니다. |
| `validation` | 목록 | 기본 제공 어댑터가 없는 파일 확장자에 필요 | 유효성 검사 명령과 그 뒤에 오는 인수입니다. 명령은 실제 대상 경로에 있는 후보 파일을 전달받으며, 파일이 유효하지 않으면 0이 아닌 상태 코드를 반환해야 합니다. |
| `check_cmd` | 문자열 | 아니요 | 번역 워크플로에서 사용할 수 있는 검사 명령입니다. |
| `check_cmds` | 맵 | 아니요 | 번역 워크플로에서 사용할 수 있는 이름이 지정된 검사 명령입니다. |
| `retries` | 정수 | 아니요 | 검사 실패 후 재시도 횟수입니다. 기본값은 `2`입니다. |
| `locale` | 문자열 | 아니요 | 로케일별 맥락 파일에 연결된 로케일입니다. |

알 수 없는 프런트매터 필드는 무시됩니다.

## 파일 형식

Glossia는 Markdown, JavaScript 객체 표기법, YAML Ain't Markup Language, Portable Object 및 일반 텍스트 파일을 기본으로 처리합니다. 그 외 파일 확장자는 적용되는 `GLOSSIA.md`에서 `validation` 명령을 선언하지 않으면 계획 생성에 실패합니다. 이를 통해 독점 구조화 형식이 제약 없는 텍스트로 조용히 처리되는 것을 방지합니다.

후보 파일을 실제 대상 경로에 임시로 작성한 후 유효성 검사 명령이 실행됩니다. 이 명령은 저장소의 기본 파서, 컴파일러 또는 빌드 명령을 호출할 수 있습니다. Glossia는 각 유효성 검사 시도 후 이전 대상을 복원하며, 승인된 후보 파일만 이후에 기록합니다.

## 소스 매핑

가장 명확한 형식은 각 소스 패턴을 출력 템플릿에 매핑하는 것입니다.

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

소스 목록도 유효하지만, 대상을 정의하려면 `output` 또는 `target_path`가 필요합니다.

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 대상 언어

목록에서는 각 로케일 코드를 언어 식별자로 사용합니다.

```yaml
targets:
  - es
  - ja
```

맵에는 읽기 쉬운 언어 이름을 추가할 수 있습니다.

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 출력 변수

| 변수 | 값 |
|---|---|
| `{locale}` 또는 `{lang}` | 대상 로케일 코드. |
| `{relpath}` | 일치한 패턴을 기준으로 한 소스 경로. |
| `{basename}` | 확장자를 제외한 소스 파일 이름. |
| `{ext}` | 앞의 점을 제외한 소스 파일 확장자. |

## 여러 규칙

콘텐츠 그룹별로 서로 다른 대상이나 검사가 필요한 경우 `translate`을 사용합니다.

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

규칙의 값은 이를 둘러싼 파일에서 상속된 값을 재정의합니다.

## 범위별 컨텍스트

Glossia는 저장소 루트부터 소스 파일까지의 경로에 있는 `GLOSSIA.md` 파일을 읽습니다.

- 상위 설정은 기본값을 제공합니다.
- 더 하위에 있는 파일은 해당 디렉터리의 필드를 재정의합니다.
- Markdown 컨텍스트는 상위에서 하위로 누적됩니다.
- 로케일별 지침과 로케일별 모델 핸들은 `GLOSSIA/<locale>.md`에 둘 수 있습니다.

이를 통해 저장소 루트에는 전반적인 보이스 지침을 유지하면서, 특정 제품 영역이나 언어에 관한 지침은 해당 콘텐츠와 가까운 위치에 둘 수 있습니다.