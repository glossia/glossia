%{
  title: "데이터 분석 SDK",
  summary: "Glossia 웹 분석에 기반한 수집된 필드, 이벤트 엔드포인트 및 개인정보 보호 모델입니다.",
  category: "참고",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 `@glossia/web` SDK 는 항상 응답합니다. `202 Accepted`, 알 수 없는 도메인이나 잘못된 페이로드를 포함하여, 어떤 프로젝트에서 분석 데이터를 수집하는지 SDK 가 누출하지 않습니다.

프로젝트는 스니펫이 선언한 사이트 도메인에 의해 결정됩니다. `d` 공식적입니다; 누락될 경우 서버는 호스트의 `u` (페이지 URL) 이며 그 후 요청 `Origin`/`Referer`.

### 요청 바디

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 문자열 | 프로젝트를 식별하는 사이트 도메인 (예 `example.com`) 필수. |
| `n`   | string | 이벤트 이름 기본값 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | 리퍼러 (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 화면 너비 (CSS 픽셀).                                  |
| `sid` | 문자열 | 탭별 세션 ID (sessionStorage, 닫을 때 초기화).       |

CORS 는 열려 있습니다 (`Access-Control-Allow-Origin: *`) 는 엔드포인트가 인증 자격을 허용하지 않기 때문입니다.

## 서버에서 파생된 필드

이들은 데이터 수집 시에 계산되며 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP, UA, 및 프로젝트의 일일 회전 해시입니다. 날짜를 넘어 연결 불가입니다.  |
| `country_code`    | GeoIP         | ISO 3166-1 알파 2 코드입니다. GeoIP 가 구성되지 않은 경우 비어 있습니다.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`\[", or"\] `opera`재조립된 문서가 이전에 유효성 검사를 실패했습니다: 마크다운 텍스트 노드 복구로 빈 번역이 생성되었습니다. `unknown`.      |
| `os`              | User-Agent    | `windows`, `macos`이전 재구성 문서가 유효성 검사를 실패했습니다: `ios`Markdown 텍스트 리터럴 복구는 길이가 일치하는 JSON 문자열 배열을 반환해야 합니다 `android`comma `linux`or `unknown`dot
pipe `hostname`        | 페이지 URL      | 소문자화된 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 요청 출처      | 요청 출처 호스트, 선두 | `www.`/`m.` 제거됨.                        |
| `browser_language`| 언어      | 가장 선호하는 정규화된 로케일 (예: `pt-BR`" )\`.                    |
| `served_locale`   | 계산된      | 선호 언어에 일치하는 지원 대상 중 첫 번째, 아니면 비어 있음.   |
| `has_locale_gap`  | 계산됨      | `1` 방문자가 프로젝트에서 지원하지 않는 언어를 선호할 때 |

## 개인정보 보호 모델

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않고 탭별 세션 ID 만 저장하며 `sessionStorage`" , 브라우저가 닫힐 때 지우며.
- **지문 식별 없음.** 캔버스, WebGL, 폰트, 오디오 핑거프린트는 수집되지 않습니다. 일일 변경되는 서버 해시는 이를 포함하지 않은 고유한 식별자를 제공합니다.
- **원본 식별자는 저장되지 않습니다.** IP 주소 및 User-Agent 는 한 번 읽혀 서버 시크릿과 일일 솔트로 해싱된 후 폐기됩니다.
- **프로젝트별 범위 설정.** 동일 브라우저가 두 프로젝트에서 사용되더라도 서로 무관한 방문자 ID 가 생성되므로, Glossia 고객 간 방문자 추적이 불가능합니다.