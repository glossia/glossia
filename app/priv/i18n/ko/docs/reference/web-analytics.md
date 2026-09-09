%{
  title: "애널리틱스 SDK",
  summary: "수집 필드, 이벤트 엔드포인트 및 Glossia 웹 애널리틱스 뒤에 있는 개인정보 보호 모델입니다.",
  category: "참조",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

SDK 에서 JSON 이벤트를 받습니다 `@glossia/web` SDK. 항상 응답합니다 `202 Accepted`, 알 수 없는 도메인 또는 잘못된 페이로드를 포함하여, SDK 가 분석 데이터 수집 프로젝트를 누설하지 않습니다.

프로젝트는 스니펫이 선언한 사이트 도메인으로 해결됩니다. `d` 공식적입니다; 없으면 서버는 호스트의 `u` (페이지 URL) 및 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 형식   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   string | 프로젝트를 식별하는 사이트 도메인 (예: `example.com`), 필수입니다. |
| `n`   | string | 이벤트 이름. 기본값으로 `pageview`.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | 출처 (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID (sessionStorage, 닫히면 초기화됨).       |

CORS 는 열려 있습니다 (`Access-Control-Allow-Origin: *`) 자격 증명을 허용하지 않기 때문입니다.)

## 서버에서 파생된 필드

수입 시 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 회전 해시. 하루를 넘어 연결되지 않습니다.  |
| `country_code`    | GeoIP         | ISO 3166-1 알파-2 코드. GeoIP 가 설정되지 않으면 비어 있습니다.        |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`, `tablet`, `bot`또는 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 리퍼러      | 리퍼러 호스트, 앞쪽 `www.`/`m.` 제거.                        |
| `browser_language`| 언어      | 가장 선호하는 정규화된 로케일 (예. `pt-BR`)                    |
| `served_locale`   | 계산      | 선호하는 언어와 일치하는 첫 지원 대상, 아니면 빈.   |
| `has_locale_gap`  | 계산됨      | `1` 프로젝트가 지원하지 않는 언어를 선호할 때 |

## 개인정보 처리 모델

- **클라이언트 측 저장 없음.** SDK 는 쿠키를 설정하지 않으며 탭별 세션 ID 만 저장하는 곳에 `sessionStorage`, 브라우저가 닫았을 때 지워집니다.
- **지문 식별 없음.** 캔버스, WebGL, 글꼴 및 오디오 지문은 수집되지 않습니다. 매일 회전하는 서버 해시는 이를 필요로 하지 않고 고유한 식별자를 제공합니다.
- **원시 식별자는 영구적으로 저장되지 않습니다.** IP 및 User-Agent 는 한 번 읽히고 서버 비밀 키와 일일 솔트로 해시된 후 폐기됩니다.
- **프로젝트별 범위 설정.** 두 프로젝트에서 동일한 브라우저가 사용되어도 연관되지 않은 방문자 ID 가 생성되므로, Glossia 고객 간 방문자를 추적할 수 없습니다.