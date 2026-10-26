%{
  title: "분석 SDK",
  summary: "수집된 필드, 이벤트 엔드포인트, 및 Glossia 웹 분석 기반의 개인정보 보호 모델",
  category: "참조",
  section: "analytics",
  order: 1
}
---

## 이벤트 엔드포인트

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 는 호환성을 위해 여전히 사용됩니다. 호스팅된 스크립트가 자체 출처에서 `/v1/collect` 를 파생하며, 패키지 통합은 `endpoint` 를 명시적으로 설정해야 합니다.

`@glossia/web` SDK 에서 JSON 이벤트를 받습니다. 미지의 도메인이나 형식이 잘못된 페이로드라도 항상 `202 Accepted` 를 응답하며, SDK 는 어떤 프로젝트에서 분석 데이터를 수집하는지 누설하지 않습니다.

프로젝트는 스니펫이 선언한 사이트 도메인으로 확인됩니다. `d` 가 우선합니다; 부재할 경우 서버는 `u` (페이지 URL) 의 호스트로 대체하고, 다음으로 요청 `Origin`/`Referer` 을 확인합니다.

### 요청 본문

| 필드 | 유형   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트를 식별하는 사이트 도메인 (예: `example.com`). 브라우저 라이브러리에 의해 전송되며, 대체 해결 방식은 위와 같습니다. |
| `n`   | string | 이벤트 이름. 기본값은 `pageview` 입니다.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | Referrer (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `sl`  | string | 실제 페이지 언어 (`document.documentElement.lang`). 미지정 시 비어 있습니다. |
| `al`  | string | `link[rel="alternate"][hreflang]` 에서 가져온 쉼표로 구분된 번역 언어, `x-default` 제외. |
| `tz`  | string | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS 픽셀 단위의 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID (sessionStorage 사용, 종료 시 삭제).       |

CORS 는 `Access-Control-Allow-Origin: *` 로 열려 있습니다. 엔드포인트는 인증 자격을 전혀 허용하지 않기 때문입니다.

## 서버에서 파생된 필드

이것들은 수집 시 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 일일 교체 해시. 일수 간 연결 불가.  |
| `country_code`    | Cloudflare / GeoIP | 신뢰할 수 있는 `CF-IPCountry` 헤더에서 가져온 ISO 3166-1 alpha-2 코드 또는 구성된 IP 지리 위치 어댑터. 둘 다 국가를 해결하지 못하면 빈 값. |
| `device`          | 사용자 에이전트    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | 사용자 에이전트    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | 사용자 에이전트    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자로 된 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | Referrer      | Referrer 호스트, 앞의 `www.`/`m.` 제거.                        |
| `browser_language`| 언어     | 가장 선호하는 일반화된 지역 (예: `pt-BR`).                    |
| `served_locale`   | 페이지 언어 | 일반화된 `sl`, 또는 수집되지 않은 경우 빈 값 (보고되지 않음으로 표시). |
| `has_locale_gap`  | 계산된      | `1` 는 방문자의 선호 언어가 프로젝트 대상, 광고 번역 (`al`), 또는 페이지 언어 (`sl`) 와 일치하지 않을 때. 누락된 선호는 격차로 세지 않습니다. |

### 클라이언트 IP 해결

프라이빗 인그레스 펙에서 들어오는 요청에 대하여, Glossia 는 nginx 의 변경된 `X-Real-IP` 헤더를 사용하며, `X-Forwarded-For` 에서의 호출자 제어 첫 번째 항목은 아닙니다. 직접적인 공공 연결은 소켓 주소를 사용합니다. 허쯔에서, 로드 밸런서와 nginx 는 모두 PROXY 프로토콜을 활성화해야 nginx 가 로드 밸런서 주소 대신 방문자 주소를 수신합니다. 기타 리버스 프록시는 인증된 소스를 사용하여 `X-Real-IP` 를 변경해야 하며, 제한되지 않은 `X-Forwarded-For` 헤더는 사용할 수 없습니다. 일반적인 차트의 전달 헤더 정책 만으로는 이 보장을 하지 않습니다. 프라이빗 펙은 신뢰할 수 있는 인프라이므로 직접적인 pod 액세스를 제한합니다.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 는 `CF-Connecting-IP` 가 프라이빗 인그레스 펙에서 들어오는 요청의 다네한 주소를 우회할 수 있게 합니다. **기본값으로 비활성화됨**이며 국가 헤더 신뢰와 무관합니다. 해당 신뢰만 활성화될 때까지 Cloudflare 인증 또는 Cloudflare 우회 요청의 위조 헤더 제거를 수행한 후만 활성화하세요. DNS 전용 배포는 비활성화 상태로 유지해야 합니다. 이 주소 또한 IP 속도 제한과 일일 방문자 해시를 키로 합니다.

### 국가 해결

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 는 `CF-IPCountry` 빠른 경로를 활성화합니다. **기본값으로 비활성화됨**입니다. 오리지뉴가 Cloudflare 을 인증하거나, Cloudflare 을 우회하는 요청을 거부하거나, 또는 인그레스가 헤더의 비신뢰할 수 있는 사본을 제거한 후만 활성화하세요. Cloudflare 의 IP 지리 위치 설정도 зоне에 대해 활성화되어야 합니다. `CF-Connecting-IP`, `CF-Ray`, 및 nginx 의 `use-forwarded-headers` 는 그 자체로는 요청을 인증하지 않습니다.

헤더 신뢰가 활성화되면 유효한 단일 ISO 국가 코드가 즉시 사용되며 IP 조회 또는 캐시 액세스 없이 진행합니다. 현재 에지 값은 모든 캐시 조회보다 항상 우선합니다. 누락, 중복, 형식 오류 또는 미지 코드 (Cloudflare 의 `XX` (미지) 와 `T1` (Tor) 코드 포함), 구성된 지리 위치 어댑터에 회귀합니다.

MaxMind 데이터베이스가 설정되지 않은 경우, 예외 조회는 `api.ipapi.is` 를 사용하며, 주요 요청이 실패하거나인지될 수 없는 국가를 반환할 경우 `api.country.is` 를 사용합니다. 각 요청은 재시도 없음으로 1 초 연결 및 응답 시간 제한을 가집니다. 양쪽 공급자 모두 성공한 결과는 Cachex 에 24 시간 동안 캐싱되며, 10 만 항목의 예약 크기 제한 및 자동 만료 회수를 갖습니다. `Cachex.fetch/3` 는 동일한 IP 에 대한 동시 누설을 하나의 해결자로 축소합니다. 실패는 캐싱되지 않습니다. 개인 및 소유 주소는 양쪽 공급자로 전달되지 않습니다.

### 누락된 페이지 언어

대시보드는 이벤트에 `sl` 가 없을 경우 **보고되지 않음** 을 표시합니다. 이는 추적기 버전과 HTML `lang` 속성 없는 페이지에서 수집된 이벤트를 포함합니다. 페이지 언어는 브라우저 선호도나 URL 에서 추론되지 않습니다. 역사적 이벤트는 해당 시점에 수집된 메타데이터를 유지하며, 새로운 추적기 버전은 이를 복구하지 않습니다.

## プライバ시 모델

- **지속적인 크로스 세션 식별자가 없습니다.** SDK 는 쿠키를 설정하지 않으며 브라우저가 종료 시 삭제하는 탭별 세션 ID 만 `sessionStorage` 에 저장합니다.
- **지문화되지 않습니다.** Canvas, WebGL, 폰트 및 오디오 지문은 수집되지 않습니다. 일일 교체 서버 해시는 이를 사용하지 않고 고유성을 제공합니다.
- **원본 식별자가 저장되지 않습니다.** IP 와 사용자는 한 번 읽혀서 서버 비밀 및 일일 소금으로 해시된 다음 버려집니다.
- **프로젝트별 범위.** 두 프로젝트에서 동일한 브라우저는 무관한 방문자 ID 를 생성하므로 방문자는 Glossia 고객 간에 추적될 수 없습니다.
