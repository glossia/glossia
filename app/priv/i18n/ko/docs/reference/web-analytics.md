%{
  title: "분석 SDK",
  summary: "Glossia 웹 분석을 뒷받침하는 수집 필드, 이벤트 엔드포인트 및 개인정보 보호 모델입니다.",
  category: "참조",
  section: "analytics",
  order: 1
}
---

## 이벤트 엔드포인트

`POST https://glossia.ai/v1/collect`

호환성을 위해 `POST /api/analytics/events` 는 여전히 사용할 수 있습니다. 호스팅된 스크립트는 자체 Origin 에서 `/v1/collect` 를 도출하며, 패키지 통합은 `endpoint` 를 명시적으로 설정해야 합니다.

`@glossia/web` SDK 에서 JSON 이벤트를 수신합니다. 알려지지 않은 도메인 또는 잘못된 페이로드의 경우에도 항상 `202 Accepted`'를 반환하여 SDK 는 어떤 프로젝트가 분석 정보를 수집하는지 누설하지 않습니다.

프로젝트는 스니펫이 선언하는 사이트 도메인으로 해결됩니다. `d` 가 우선입니다. 부재 시 서버는 `u`(페이지 URL) 의 호스트로 fallback 한 후 요청의 `Origin`/`Referer` 로 fallback 합니다.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 문자열 | 프로젝트를 식별하는 사이트 도메인 (예: `example.com`) . 브라우저 라이브러리에 의해 전송되며, fallback 해결은 위서 설명됩니다. |
| `n`   | 문자열 | 이벤트 이름. 기본값 `pageview` 입니다.                          |
| `u`   | 문자열 | 페이지 URL (`location.href`).                                  |
| `r`   | 문자열 | 레퍼러 (`document.referrer`).                              |
| `l`   | 문자열 | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `sl`  | 문자열 | 실제 페이지 언어 (`document.documentElement.lang`). 미선언 시 빈 값입니다. |
| `al`  | 문자열 | `x-default` 를 제외하고 `link[rel="alternate"][hreflang]` 에서 가져온 쉼표로 구분된 번역 언어. |
| `tz`  | 문자열 | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | 숫자 | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | 문자열 | 탭별 세션 ID (sessionStorage, 닫힐 때 지움)       |

엔드포인트가 자격 증명을 허용하지 않기 때문에 CORS 는 열려 있습니다 (`Access-Control-Allow-Origin: *`).

## 서버에서 파생된 필드

수집 시 계산되며 서버 측에 저장됩니다. 원본 IP 와 사용자 에이전트는 절대 저장되지 않습니다.

| 필드             | 소스        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 회전 해시. 일일 연결은 불가능합니다.  |
| `country_code`    | Cloudflare / GeoIP | 신뢰할 수 있는 `CF-IPCountry` 헤더에서 가져온 ISO 3166-1 alpha-2 코드 또는 설정된 IP 지오위치 어댑터. 둘 다 국가를 해결하지 않을 때 빈 값입니다. |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | 사용자 에이전트    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 대문자를 소문자로 변환한 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 레퍼러      | 레퍼러 호스트, 앞에 있는 `www.`/`m.` 를 제거.                        |
| `browser_language`| 언어     | 가장 선호하는 정규화된 로컬선 (예: `pt-BR`).                    |
| `served_locale`   | 페이지 언어 | 정규화된 `sl`, 또는 수집되지 않은 경우 빈 값 (Not reported 로 표시). |
| `has_locale_gap`  | 계산됨      | `1` 는 방문자의 선호 언어가 프로젝트 대상, 광고된 번역 (`al`), 또는 페이지 언어 (`sl`) 와 일치하지 않을 때 1 이며, 누락된 선호는 간격으로 간주하지 않습니다. |

### 국가 해결

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 는 `CF-IPCountry` 빠른 경로를 활성화합니다. 그것은 **기본값으로 비활성입니다**. Origin 이 Cloudflare 을 인증하거나, Cloudflare 을 우회하는 요청을 거부하거나, Ingress 가 헤더의 비신뢰할 수 있는 사본을 제거하는 경우에만 활성화해야 합니다. Zone 에서 Cloudflare IP 지오위치 설정도 활성화해야 합니다. `CF-Connecting-IP`, `CF-Ray` 및 nginx 의 `use-forwarded-headers` 는 요청을 자체적으로 인증하지 않습니다.

헤더 신뢰가 활성화되면, IP 조회 또는 캐시 액세스 없이 유효한 단일 ISO 국가 코드를 즉시 사용합니다. 현재 Edge 값은 항상 어떤 캐시 조회보다 우선합니다. 누락, 중복, 변형, 또는 알려지지 않은 코드 (Cloudflare 의 `XX` (Unknown) 나 `T1` (Tor) 포함) 는 설정된 지오위치 어댑터로 fallback 합니다.

설정된 MaxMind 데이터베이스가 없으면, fallback 조회는 `api.ipapi.is` 에서 사용하고 주요 요청이 실패하거나 알려진 국가를 반환하지 않을 때 `api.country.is` 를 사용합니다. 각 요청은 재시도가 비활성화된 1 초 연결 및 응답 타임아웃을 포함합니다. 제공자의 성공 결과 모두는 Cachex 에서 24 시간 동안 캐시되며, 100,000 항목의 예약된 크기 제한 및 자동 만료 회수 기능을 포함합니다. `Cachex.fetch/3` 는 같은 IP 에 대한 병렬 누락을 하나의 해결기로 축소합니다. 실패는 캐시되지 않습니다. 사유 및 예약 주소는 제공자에게 전송되지 않습니다.

### 누락된 페이지 언어

대시보드는 이벤트가 `sl` 를 갖지 않을 때 **Not reported** 를 표시합니다. 이는 더 오래된 추적 버전에서 수집된 이벤트와 HTML `lang` 속성이 없는 페이지에 포함됩니다. 페이지 언어는 브라우저 선호도나 URL 에서 추론되지 않습니다. 역사적 이벤트는 당시 수집된 메타데이터를 유지하며; 새로운 추적 버전은 이를 복원하지 않습니다.

## 개인정보 처리 모델

- **지속 가능한 세션 간 식별자가 없습니다.** SDK 는 쿠키를 설정하지 않으며, 브라우저가 닫힐 때 지우는 `sessionStorage` 인 탭별 세션 ID 만 저장합니다.
- **지문 인식이 사용됩니다.** 캔버스, WebGL, 폰트 및 오디오 지문 등은 수집되지 않습니다. 일일 회전 서버 해시는 이를 사용하지 않고 고유성을 제공합니다.
- **원본 식별자가 유지되지 않습니다.** IP 와 사용자 에이전트는 한 번 읽히며 서버 시크릿과 일일 솔트로 해시되어 버려집니다.
- **프로젝트별 범위.** 동일한 브라우저가 두 프로젝트에서 사용하면 관련 없는 방문자 ID 가 생성되므로 방문자는 Glossia 고객 간에 추적될 수 없습니다.
