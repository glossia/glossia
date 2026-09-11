%{
  title: "분석 SDK",
  summary: "수집 필드, 이벤트 엔드포인트, 및 Glossia 웹 분석 기반 프라이버시 모델입니다.",
  category: "참조",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 받습니다. `@glossia/web` SDK 입니다. 항상 응답합니다. `202 Accepted`, 알려지지 않은 도메인이나 잘못된 페이로드인 경우에도 응답하므로, SDK 가 분석 데이터를 수집하는 프로젝트를 누설하지 않습니다.

프로젝트는 코드 조각이 지정하는 사이트 도메인으로 결정됩니다. `d` 이는 우선적입니다; 누락된 경우 서버 는 ( 페이지 URL) 의 호스트로 되돌립니다 `u` ( 페이지 URL) 및 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 타입     | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트를 식별하는 사이트 도메인 (예:) `example.com`). 필수. |
| `n`   | string | 이벤트 이름. 기본값은 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`)                                  |
| `r`   | string | 리퍼러 (`document.referrer`)                              |
| `l`   | 문자열 | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | 문자열 | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | 숫자 | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID (sessionStorage, 닫힘 시 삭제됨).       |

CORS 는 열려 있으며 (`Access-Control-Allow-Origin: *`) 엔드포인트는 인증 정보를 요구하지 않습니다.

## 서버 파생 필드

수집 시 계산되며 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대로 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 회전 해시. 날짜 간 연결 불가.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 코드. GeoIP 가 설정되지 않았을 때 비어있습니다.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`이전 조립 문서 검증에 실패했습니다: 마크다운 텍스트 리터럴 복원은 길이가 일치하는 JSON 문자열 배열을 반환해야 합니다 `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 컴포넌트.                                                     |
| `referrer_source` | 래퍼러      | 래퍼러 호스트, 앞쪽 `www.`/`m.` 제거됨.                        |
| `browser_language`| 언어     | 가장 선호하는 정규화된 로케일 (예. `pt-BR`).                    |
| `served_locale`   | 계산됨      | 선호 언어와 일치하는 첫 번째 지원 대상, 없으면 공백.   |
| `has_locale_gap`  | 계산됨      | `1` 프로젝트가 지원하지 않는 언어를 선호하는 방문자일 때입니다. |

## 개인정보 처리 모델

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않으며 탭별 세션 ID 만 `sessionStorage`, 브라우저가 닫히면 삭제됩니다.
- **지문 식별 없음.** 캔버스, WebGL, 폰트 및 오디오 지문은 수집되지 않습니다. 일일 회전 서버 해시는 이를 수집하지 않고 고유한 식별자를 제공합니다.
- **원시 식별자는 지속되지 않습니다.** IP 주소와 User-Agent 는 한 번만 읽히고, 서버 비밀키와 일일 솔트로 해시된 후 폐기됩니다.
- **프로젝트별 범위 설정.** 두 프로젝트에서 동일한 브라우저가 사용되더라도 서로 다른 방문자 ID 가 생성되어 Glossia 고객 간에 방문자를 추적할 수 없습니다.