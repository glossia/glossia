%{
  title: "Analytics SDK",
  summary: "수집된 필드, 이벤트 엔드포인트 및 Glossia 웹 분석의 기반이 되는 개인 정보 보호 모델.",
  category: "참고",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 `@glossia/web` SDK 로부터 받습니다. 항상 응답합니다 `202 Accepted`, 알려지 않은 도메 인 또는 잘못된 페이로드 에 응답하며, SDK 가 분석 데이터를 수집하는 프로젝트를 누출하지 않습니다.

프로젝트는 스니펫 이 명시한 사이트 도메인 으로 결정되며 `d` 권위를 가지며; 부재 시 서버 는 호스트의 `u` ( 페이지 URL ) 이며 그 다음 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Site domain that identifies the project (e.g. `example.com`). Required. |
| `n`   | string | 이벤트 이름. 기본값 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | referer (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 화면 너비 (CSS 픽셀).                                  |
| `sid` | 문자열 | 탭별 세션 ID (sessionStorage, 닫기 시 지워짐).       |

CORS 는 열려 있()`Access-Control-Allow-Origin: *`) 엔드포인트는 자격 증명을 요구하지 않기 때문입니다.

## 서버 파생 필드

수집 시 계산 후 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 매일 회전하는 해시. 일별 연결 불가.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 코드. GeoIP 설정되지 않은 경우 비어 있음.        |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`, `tablet`, `bot`, or `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`, `opera`또는 `unknown`.       |
| `os`              | 사용자 에이전트    | `windows`, `macos`, `ios`, `android`, `linux`또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 추천 사이트      | 추천 사이트 호스트, 앞에 `www.`/`m.` 제거되었습니다.                        |
| `browser_language`| 언어         | 가장 선호되는 정규화된 로케일 (예. `pt-BR`"\\"    |
| `served_locale`   | 계산됨         | 선호 언어와 일치하는 첫 번째 지원 대상, 아니면 비어 있음.   |
| `has_locale_gap`  | 계산됨      | `1` 방문자가 프로젝트에서 지원하지 않는 언어를 선호할 때. |

## 개인정보 보호 모델

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않으며 탭별 세션 ID 만 저장합니다. `sessionStorage`, 브라우저는 종료 시 이를 지웁니다.
- **지문 식별 없음.** 캔버스, WebGL, 폰트 및 오디오 지문은 수집되지 않습니다. 일일 회전 서버 해시는 이를 필요로 하지 않고도 고유 식별자를 제공합니다.
- **원본 식별자는 지속적으로 저장되지 않습니다.** IP 와 User-Agent 는 한 번만 판독되며, 서버 시크릿과 일일 솔트로 해싱된 후 폐기됩니다.
- **프로젝트별 범위.** 두 프로젝트에서 동일한 브라우저가 관련 없는 방문자 ID 를 생성하므로, Glossia 고객 간에 방문자를 추적할 수 없습니다.