%{
  title: "분석 SDK",
  summary: "수집되는 필드, 이벤트 엔드포인트, Glossia 웹 분석의 기반이 되는 개인정보 보호 모델입니다.",
  category: "reference",
  order: 1
}
---
## 이벤트 엔드포인트

`POST /api/analytics/events`

`@glossia/web` SDK에서 JSON 이벤트를 수신합니다. 알 수 없는 도메인이나 잘못된 형식의 페이로드를 포함한 모든 요청에 항상 `202 Accepted`로 응답하므로, SDK를 통해 분석 데이터를 수집하는 프로젝트가 노출되지 않습니다.

프로젝트는 스니펫에 선언된 사이트 도메인을 기준으로 확인됩니다. `d` 값이 우선 적용됩니다. 이 값이 없으면 서버는 `u`(페이지 URL)의 호스트를 사용하고, 그다음 요청의 `Origin`/`Referer` 값을 사용합니다.

### 요청 본문

| 필드 | 유형   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 문자열 | 프로젝트를 식별하는 사이트 도메인(예: `example.com`). 필수입니다. |
| `n`   | 문자열 | 이벤트 이름. 기본값은 `pageview`입니다.                          |
| `u`   | 문자열 | 페이지 URL(`location.href`).                                  |
| `r`   | 문자열 | 리퍼러(`document.referrer`).                              |
| `l`   | 문자열 | 브라우저 언어(`navigator.languages.join(",")`).         |
| `tz`  | 문자열 | IANA 시간대(`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | 숫자 | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | 문자열 | 탭별 세션 ID(sessionStorage에 저장되며 탭을 닫으면 삭제됨).       |

엔드포인트가 자격 증명을 받지 않으므로 CORS는 모든 출처에 허용됩니다(`Access-Control-Allow-Origin: *`).

## 서버에서 파생되는 필드

다음 필드는 수집 시 계산되어 서버 측에 저장됩니다. 원본 IP 주소와 User-Agent는 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트를 조합하여 매일 갱신되는 해시입니다. 날짜가 다르면 서로 연결할 수 없습니다.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 코드입니다. GeoIP가 구성되지 않은 경우 비어 있습니다.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` 또는 `unknown`입니다.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` 또는 `unknown`입니다.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` 또는 `unknown`입니다.        |
| `hostname`        | 페이지 URL      | 소문자로 변환된 호스트입니다.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소입니다.                                                     |
| `referrer_source` | 리퍼러      | 선행 `www.`/`m.`가 제거된 리퍼러 호스트입니다.                        |
| `browser_language`| 언어     | 선호도가 가장 높은 정규화된 로케일입니다(예: `pt-BR`).                    |
| `served_locale`   | 계산값      | 선호 언어와 일치하는 첫 번째 지원 대상 언어이며, 일치 항목이 없으면 비어 있습니다.   |
| `has_locale_gap`  | 계산값      | 방문자가 프로젝트에서 제공하지 않는 언어를 선호하는 경우 `1`입니다. |

## 개인정보 보호 모델

- **클라이언트 측 저장소를 사용하지 않습니다.** SDK는 쿠키를 설정하지 않으며, 탭별 세션 ID만 `sessionStorage`에 저장합니다. 브라우저를 닫으면 이 데이터가 삭제됩니다.
- **핑거프린팅을 사용하지 않습니다.** Canvas, WebGL, 글꼴 및 오디오 핑거프린트를 수집하지 않습니다. 매일 갱신되는 서버 해시를 통해 이러한 정보 없이 고유 방문자를 식별합니다.
- **원시 식별자를 보관하지 않습니다.** IP와 User-Agent는 한 번만 읽은 후 서버 비밀 값 및 일일 솔트와 함께 해시 처리되며, 이후 폐기됩니다.
- **프로젝트별로 범위를 제한합니다.** 동일한 브라우저에서 두 프로젝트에 접속해도 서로 연관되지 않는 방문자 ID가 생성되므로 Glossia 고객 간에 방문자를 추적할 수 없습니다.