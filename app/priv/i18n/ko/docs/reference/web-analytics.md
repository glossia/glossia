%{
  title: "애널리틱스 SDK",
  summary: "수집 필드, 이벤트 엔드포인트, 및 Glossia 웹 분석 뒤의 프라이버시 모델",
  category: "참조",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 받습니다 `@glossia/web` SDK 는 항상 응답합니다 `202 Accepted`, 알려지지 않은 도메인이나 잘못된 페이로드의 경우에도 응답하므로, SDK 는 어떤 프로젝트가 분석을 수집하는지 누출하지 않습니다

프로젝트는 스니펫에서 지정한 사이트 도메인으로 해결됩니다 `d` 권위 있는 것으로 간주됩니다; 해당 도메인이 없을 경우 서버는 호스트의 `u` (페이지 URL) 이후 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 유형   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 문자열 | 프로젝트를 식별하는 사이트 도메인 (예. `example.com`). 필수. |
| `n`   | string | 이벤트 이름. 기본값. `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | 리퍼러 (`document.referrer`).                              |
| `l`   | string | 브라우저 언어(`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 시간대(`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID(sessionStorage, 닫을 때 삭제됨).       |

CORS 는 허용되었습니다 (`Access-Control-Allow-Origin: *`) 엔드포인트가 자격 증명을 요구하지 않기 때문입니다.

## 서버 파생 필드

이들은 수집 시 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 소스        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 회전 해시. 날짜를 가로지르는 연결 불가.  |
| `country_code`    | GeoIP         | ISO 3166-1 알파 -2 코드. GeoIP 설정되지 않으면 빈 상태.        |
| `device`          | 사용자 에이전트    | `desktop`| `mobile`| `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`이전에 다시 조립된 문서가 유효성 검사에 실패했습니다: 마크다운 텍스트 문자리 복구 는 일치하는 길이의 JSON 문자열 배열을 반환해야 합니다 `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | Referrer      | Referrer 호스트, 시작 부분의 `www.`/`m.` 제거됩니다.                        |
| `browser_language`| 언어     | 가장 선호하는 정규화된 로케일 (예: `pt-BR`) .                    |
| `served_locale`   | 계산   | 선호 언어와 일치하는 첫 번째 지원 가능한 타겟이거나 비어 있습니다.   |
| `has_locale_gap`  | 계산된      | `1` 로젝트에서 제공하지 않는 언어를 선호할 때.

## 프라이버시 모델

- **클라이언트 사이드 저장 없음.** SDK 는 쿠키를 설정하지 않으며 주문 탭 세션 ID 만 `sessionStorage`브라우저가 닫도록 지웁니다.
- **지문 추적 없음.** 캔버스, WebGL, 글꼴 및 오디오 지문은 수집되지 않습니다. 일일 회전 서버 해시는 이를 사용하지 않으면서 고유한 식별자를 제공합니다.
- **원시 식별자가 영구 저장되지 않습니다.** IP 주소 및 User-Agent 는 한 번만 읽히고 서버 기밀과 일일 소금으로 해싱된 후 폐기됩니다.
- **프로젝트별 범위.** 두 프로젝트에서 동일한 브라우저는 연관되지 않은 방문자 ID 를 생성하므로 Glossia 고객 간에 방문자를 추적할 수 없습니다.