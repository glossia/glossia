%{
  title: "분석 SDK",
  summary: "수집된 필드, 이벤트 엔드포인트, 그리고 Glossia 웹 분석 뒤에 있는 프라이버시 모델입니다.",
  category: "참조",
  order: 1
}
---
## 이비 트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 `@glossia/web` SDK. 항상 응답합니다 `202 Accepted`알려지지 않은 도메인이나 형식이 잘못된 페이로드의 경우에도 응답하므로 SDK 가 어떤 프로젝트에서 분석 데이터를 수집하는지 절대 유출되지 않습니다.

프로젝트는 스니펫이 선언한 사이트 도메인 으로 결정됩니다. `d` 권위적입니다. 누락되면 서버는 호스트의 `u` (페이지 URL) 이어서 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 타입 | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트를 식별하는 사이트 도메인 (예:" `example.com`. 필수입니다. |
| `n`   | string | 이벤트 이름. 기본값으로 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | 참조 (`document.referrer`).                              |
| `l`   | 문자열 | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | 문자열 | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | 숫자 | CSS 픽셀 단위 화면 너비.                                  |
| `sid` | string | Per-tab session id (sessionStorage, cleared on close).       |

CORS is open (`Access-Control-Allow-Origin: *`) because the endpoint accepts no credentials.

## Server-derived fields

These are computed at ingestion and stored server-side. The raw IP and User-Agent are never stored.

| Field             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 회전 해시. 일자 간 연결 불가  |
| `country_code`    | GeoIP         | ISO 3166-1 알파-2 코드. GeoIP 가 구성되지 않았을 때 비어 있음.        |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | 사용자 에이전트    | `windows`, `macos`, `ios`, `android`, `linux`, or `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 컴포넌트.                                                     |
| `referrer_source` | Referrer      | Referrer 호스트, 선두 `www.`/`m.` 제거됨.                        |
| `browser_language`| 언어     | 가장 선호되는 정규화된 지역 (예 `pt-BR`")                    |
| `served_locale`   | 계산됨      | 선호하는 언어와 일치하는 첫 번째 지원 타겟, 없으면 공백입니다.   |
| `has_locale_gap`  | 자동 감지됨      | `1` 프로젝트가 지원하지 않는 언어를 방문자가 선호할 때. |

## 개인정보 처리 방식

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않고 탭별 세션 ID 만 저장하며 `sessionStorage`, 브라우저가 닫히면 삭제됩니다.
- **지문 식별 없음.** 캔버스, WebGL, 폰트 및 오디오 지문은 수집되지 않습니다. 일일 교체되는 서버 해시는 이를 사용하지 않아도 고유한 식별자를 제공합니다.
- **원본 식별자는 저장되지 않습니다.** IP 와 User-Agent 는 한 번 읽혀 서버 비밀 키와 일일 솔트로 해시 처리된 후 폐기됩니다.
- **프로젝트별 범위 설정.** 동일한 브라우저가 두 프로젝트에서 사용되더라도 서로 관련 없는 방문자 ID 가 생성되므로, Glossia 고객 간에 방문자를 추적할 수 없습니다.