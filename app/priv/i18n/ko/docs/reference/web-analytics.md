%{
  title: "애널리틱스 SDK",
  summary: "Glossia 웹 분석의 수집 필드, 이벤트 엔드포인트, 및 프라이버시 모델입니다.",
  category: "참고",
  section: "analytics",
  order: 1
}
---
## 이벤트 엔드포인트

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 호환성을 위해 계속 사용 가능합니다. 호스팅된 스크립트는 `/v1/collect` 자체 오리진에서 유래되며; 패키지 통합은 설정해야 `endpoint` 명시적으로.

SDK 에서의 JSON 이벤트를 `@glossia/web` SDK. 항상 응답합니다. `202 Accepted`, 알 수 없는 도메인이나 형식이 잘못된 페이로드를 포함하며, 어떤 프로젝트가 분석 데이터를 수집하는지를 SDK 는 누설하지 않습니다.

프로젝트는 스니펫이 명시하는 사이트 도메인에 의해 결정됩니다. `d` 권위적입니다.; 부재할 경우 서버는 해당 호스트의 `u` (페이지 URL) 그리고 요청 `Origin`/`Referer`.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트 식별용 사이트 도메인 (예: `example.com`). 브라우저 라이브러리에서 발송되었습니다; 위에서 대체 처리가 설명되어 있습니다. |
| `n`   | string | 이벤트 이름. 기본값 `pageview`.                          |
| `u`   | 문자열 | 페이지 URL (`location.href`)                                  |
| `r`   | string | 출처 URL (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `sl`  | string | 실제 페이지 언어 (`document.documentElement.lang`). 정의되지 않았을 경우 비어있음. |
| `al`  | 문자열 | 쉼표로 구분된 번역 언어 목록에서 `link[rel="alternate"][hreflang]`, 제외 `x-default`. |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`) . |
| `sw`  | number | CSS 픽셀 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID (sessionStorage, 닫을 때 제거).       |

CORS 는 개방되었습니다 (`Access-Control-Allow-Origin: *`) 엔드포인트가 자격 증명을 허용하지 않기 때문입니다.

## 서버에서 파생된 필드

수입 시 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트를 위한 일일 회전 해시. 날짜 간 연결 불가.  |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2 코드에서 신뢰할 수 있는 `CF-IPCountry` 헤더, 또는 설정된 IP 지리 위치 어댑터의 경우. 국가를 식별하지 못하면 공백입니다. |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`이전에 유효성 검사를 통과하지 못한 재구성된 문서: 마크다운 텍스트 노드 복구가 빈 번역을 생성했습니다 `tablet`이전 재조립된 문서가 유효성 검사를 통과하지 못했습니다: Markdown 텍스트 노드 복구가 빈 번역을 생성했습니다. `bot`, 다른 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 요소.                                                     |
| `referrer_source` | 참조 URL      | 참조 호스트, 앞 `www.`/`m.` 처리되었습니다.                        |
| `browser_language`| 언어     | 가장 선호되는 정규화된 로케일 (예를 들어. `pt-BR`.                    |
| `served_locale`   | 페이지 언어 | 일반화 `sl`, 또는 비어있음 (보고되지 않음으로 표시됨) 수집되지 않았다면 |
| `has_locale_gap`  | 계산됨      | `1` 방문자의 선호 언어가 프로젝트 목표, 공지된 번역 (`al`), 또는 페이지 언어와 일치하지 않을 때 (`sl`). 누락된 선호도는 차이라고 간주되지 않습니다. |

### 국가 해상도

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 활성화하며 `CF-IPCountry` 빠른 경로입니다. 이는 **기본으로 비활성화됩니다**. 활성화하려면 원본에서 Cloudflare 가 인증되고, Cloudflare 를 우회하는 요청이 거부되거나, 인그레스 가 신뢰할 수 없는 헤더 복사본을 제거한 후에만 가능해야 합니다. 또한 해당 영역에 대해 Cloudflare 의 IP 지리 위치 설정도 활성화되어야 합니다. `CF-Connecting-IP`, `CF-Ray`, 그리고 nginx 의 `use-forwarded-headers` 자체적으로 요청을 인증하지 않습니다.

헤더 신뢰가 활성화되면, IP 조회 또는 캐시 접근 없이 즉시 유효한 단일 ISO 국가 코드가 사용됩니다. 현재 에지 값은 항상 캐시 조회보다 우선합니다. 누락, 중복, 잘못된 형식 또는 알려지지 않은 코드, Cloudflare 의 포함 `XX` (알 수 없음) 및 `T1` (Tor) 값의 경우, 설정된 지리 위치 어댑터로 복귀합니다.

MaxMind 데이터베이스가 구성되어 있지 않은 경우, 대체 검색은 `api.ipapi.is`, 다음으로 `api.country.is` 주요 요청이 실패하거나 인식할 수 있는 국가를 반환하지 않을 때. 각 요청은 재시도 없이 1 초의 연결 및 응답 타임아웃을 가지며, 성공 결과는 각 제공자에서 Cachex 에서 24 시간 동안 캐싱되며 100,000 엔트리의 예약된 크기 제한과 자동 만료 회수가 적용됩니다. `Cachex.fetch/3` 동시 누수를 같은 IP 에 대해 하나의 리졸버로 병합합니다. 실패는 캐싱되지 않습니다. 사설 및 예약 주소는 제공자 어느 쪽에도 전송되지 않습니다.

### 페이지 언어 누락

대시보드에 표시됩니다 **보고되지 않음** 이벤트가 해당 속성이 없을 때 `sl`. 이는 구버전 트래커에서 수집된 이벤트 및 HTML `lang` 속성이 없는 페이지도 포함합니다. 페이지 언어는 브라우저 설정이나 URL 에서 유추되지 않습니다. 기존 이벤트는 수집 당시의 메타데이터를 유지하며, 새로운 트래커 버전은 이를 보충하지 않습니다.

## 프라이버시 모델

- **지속적인 세션 간 식별자가 없습니다.** SDK 는 쿠키를 설정하지 않으며 탭별 세션 id 만 `sessionStorage`브라우저가 닫을 때 지워집니다.
- **지문 수집 없음.** Canvas, WebGL, 글꼴 및 오디오 지문은 수집되지 않습니다. 매일 교체되는 서버 해시는 지문 없이 고유 값을 제공합니다.
- **원본 식별자는 지속 저장되지 않습니다.** IP 와 User-Agent 는 한 번 읽혀 서버 비밀값 및 일일 솔트로 해싱된 후 폐기됩니다.
- **프로젝트별 범위.** 두 프로젝트에서 동일한 브라우저는 연관성 없는 방문자 ID 를 생성하므로, Glossia 고객 간 방문자 추적이 불가능합니다.