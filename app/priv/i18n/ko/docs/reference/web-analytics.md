%{
  title: "분석 SDK",
  summary: "수집된 필드, 이벤트 엔드포인트 및 Glossia 웹 분석 뒤의 개인정보 처리 모델입니다.",
  category: "참조",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 받습니다 `@glossia/web` SDK. 항상 응답합니다 `202 Accepted`, 알려지지 않은 도메인이나 변형된 페이로드가 포함됨에도 불구하고 SDK 는 분석 데이터를 수집하는 어떤 프로젝트인지 절대 누설하지 않습니다.

프로젝트는 스니펫이 선언하는 사이트 도메인에 의해 결정됩니다. `d` 이 도메인은 우세합니다; 없으면 서버는 요청 호스트로 되돌아갑니다 `u` (페이지 URL) 이후에 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트를 식별하는 사이트 도메인 (e.g. `example.com`). 필수. |
| `n`   | string | 이벤트명. 기본값 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | 리퍼러 (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | 문자열 | 탭별 세션 ID (sessionStorage, 닫힐 때 삭제됨).       |

CORS 는 허용됨 (`Access-Control-Allow-Origin: *`) 엔드포인트가 자격 증명을 요구하지 않기 때문입니다.

## 서버에서 파생된 필드

이는 수집 시 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드               | 출처              | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트 를 기반으로 한 매일 회전하는 해시입니다. 날짜 간 연결 불가  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 코드입니다. GeoIP 가 설정되지 않으면 공백입니다.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`\[", ", ", 또는"\] `bot`다시 조립된 문서가 이전에 유효성 검사를 통과하지 못했습니다. Markdown 텍스트 리터럴 복구 과정에서 잘못된 JSON 이 반환되었습니다. `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`| `linux`| `unknown`또는
| `hostname`        | Page URL      | 소문자 호스트.                                                    |
| `pathname`        | Page URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 리퍼러      | 리퍼러 호스트, 앞쪽 `www.`/`m.` 제거됨.                        |
| `browser_language`| 언어       | 가장 선호하는 정규화된 로케일 (예. `pt-BR`)                    |
| `served_locale`   | 계산       | 선호 언어와 일치하는 첫 지원 대상, 아니면 빈 값.   |
| `has_locale_gap`  | 계산됨      | `1` 프로젝트가 지원하지 않는 언어를 방문자가 선호하는 경우입니다. |

## 개인 정보 모델

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않으며 탭별 세션 ID 만 `sessionStorage`, 브라우저가 종료 시 지웁니다.
- **지문 식별 없음.** 캔버스, WebGL, 글꼴 및 오디오 지문은 수집되지 않습니다. 일일 교체되는 서버 해시는 이 정보 없이도 고유한 식별자를 제공합니다.
- **원시 식별자는 영구 저장되지 않습니다.** IP 주소 및 User-Agent 는 한 번만 읽히고, 서버 비밀키와 일일 솔트와 함께 해시된 후 삭제됩니다.
- **프로젝트별 범위.** 동일한 브라우저가 두 프로젝트에서 사용되어도 서로 무관한 방문자 ID 가 생성되므로, Glossia 고객 간에 방문자 추적이 불가능합니다.