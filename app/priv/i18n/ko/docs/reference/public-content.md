%{
  title: "공개 콘텐츠 및 크롤러 인터페이스",
  summary: "공개 웹사이트의 HTML, 마크다운, 검색, 캐싱 및 크롤러 범위",
  category: "참고",
  section: "platform",
  order: 10
}
---

Glossia 는 계정과 프로젝트 애플리케이션 표면과 별도로 게시된 웹사이트 콘텐츠를 노출합니다.

## 표현

| 인터페이스 | 동작 |
|---|---|
| 게시된 HTML URL | 정준 메타데이터와 Markdown 대체 `Link` 응답 헤더를 포함하는 브라우저 표현입니다. |
| 해당 URL 에서의 `Accept: text/markdown` | 명시적 미디어 타입의 품질이 양수이며 `text/html` 보다 덜 선호되지 않을 때의 Markdown 표현입니다. |
| `.md` 가 붙은 페이지 URL | 브라우저 언어 선호도와 관계없는 명시적 Markdown 표현입니다. |
| `/index.md` | 홈페이지의 Markdown 개요입니다. |
| `/docs.md`, `/blog.md`, `/features.md` | 게시된 콘텐츠의 Markdown 인덱스입니다. |
| `/changelog.md` | 하나의 Markdown 문서에 포함된 게시된 변경 로그 항목입니다. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | 최신 게시된 법적 문서입니다. 날짜가 있는 법적 URL 도 또한 `.md` 을 지원합니다. |

`*/*` 만으로는 Markdown 을 선택하지 않습니다. HTML 응답과 Markdown 응답은 `Vary: Accept` 를 공유하므로 캐시는 표현을 혼용하지 않습니다.

개별 문서, 블로그, 기능 및 법적 콘텐츠는 렌더링된 HTML 의 변환이 아닌 작성된 Markdown 을 사용합니다. 인덱스 페이지는 게시된 인벤토리에서 생성되며, 홈페이지에는 큐레이팅된 Markdown 개요가 있습니다. 대화형 REST 참조는 독자를 브라우저 전용 API 위젯의 임베딩 대신 OpenAPI 사양으로 안내합니다.

## 지역 설정

영어는 접두사가 없습니다. 번역된 마케팅 URL 은 기본 접두사를 사용합니다: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br`, 및 `/zh-hans`. 예를 들어, `/es/docs/tutorials/getting-started.md` 는 게시될 때 스페인 버전을 제공합니다.

URL 이 Markdown 콘텐츠의 언어를 선택합니다. `Accept-Language` 는 Markdown 요청을 리디렉션하지 않습니다. 콘텐츠 번역이 누락된 경우 영어 원본으로 되돌립니다. 홈페이지 개요는 현재 영어로 작성되었습니다.

## 검색

- `/robots.txt` 는 기본적으로 크롤링을 금지하며 유한한 게시된 HTML 과 Markdown 인벤토리, 로컬라이즈된 피드, `/assets/`, `/fonts/`, 및 `/images/` 아래의 렌더링 자산, favicon 과 `/og/marketing/` 아래의 공개 마케팅 미리보기를 포함합니다. `/og/app/` 아래의 계정 미리보기 이미지는 여전히 금지됩니다. 이는 상호운용성 크롤러에 대한 안내일 뿐 권한 부여 메커니즘이 아닙니다.
- `/sitemap.xml` 는 지역 변형이 있는 정준 공인 HTML 콘텐츠를 나열합니다. 변경 로그 프레그먼트는 별도의 URL 이 아닙니다.
- `/llms.txt` 는 Glossia 를 소개하며 공개 문서, 기능 가이드 및 최근 글 (명시적 Markdown 링크 포함) 로 링크합니다.
- `/llms-full.txt` 는 Markdown 을 포함하는 한 개의 텍스트 문서로 홈페이지 개요와 완전한 문서 인벤토리를 추출합니다.

인증, 계정 대시보드, API 및 기타 애플리케이션 응답은 `noindex, nofollow` 로 표시됩니다. 게시된 성공 콘텐츠는 `index, follow` 로 표시됩니다; 오류는 색인화할 수 없습니다. 검색용 텍스트 파일 (`/robots.txt`, `/llms.txt`, 및 `/llms-full.txt`) 는 `noindex, follow` 을 사용하며: 독자는 파일을 가져오고 링크를 따를 수 있지만, 검색 엔진은 중복 문서 덤프 대신 정준 페이지를 인덱싱해야 합니다.

## 캐싱 및 자원 사용

Markdown 및 텍스트 검색 응답에는 다음이 포함됩니다:

| 헤더 | 값 또는 의미 |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, 또는 검색용 텍스트의 경우 `text/plain; charset=utf-8`. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | 표현의 인용된 SHA-256 요약값입니다. |
| `X-Markdown-Tokens` | 문자를 4로 나누고 올림으로 근사인 추정치; 모델별 토크나이저 카운트가 아닙니다. |

`If-None-Match` 는 강하거나 약한 유효성 검사자, 다중 유효성 검사자 및 `*` 와의 매칭을 지원합니다. 매칭 결과는 바디 없이 `304` 을 반환합니다. `HEAD` 는 바디 없이 표현 헤더만 반환합니다.

게시된 Markdown 인벤토리는 릴리스에 컴파일됩니다. 요청은 콘텐츠 변환 수행, 소스 파일 읽기, 인증된 계정 로드 또는 LiveView 렌더링을 수행하지 않습니다. 이러한 공개 표현에 액세스하기 위해 User-Agent 위장이 필요하지 않습니다.

## 운영적 경계

Markdown 협상은 계정 또는 프로젝트 대시보드에 액세스하지 못하게 합니다. 기존 계정 브라우징 속도 제한 및 Turnstile 검사는 별도의 보호 장치로 남아 있습니다.

프로덕션 에지 속도 제한은 `GET` 및 `HEAD` 모두에 적용됩니다. 검증된 크롤러 또한 속도 제한을 받습니다. 초과 요청은 브라우저 챌린지 대신 속도 제한 응답을 받으며, 독자는 요청 속도를 늦추고 나중에 재시도해야 합니다. 공유 캐싱 및 조건부 요청은 클라이언트를 속도 제한에서 면제하지 않습니다.

리포지토리의 크롤러 정책 변경 사항은 애플리케이션 및 관련 인프라 구성이 배포된 후에야 효력을 발생시킵니다.
