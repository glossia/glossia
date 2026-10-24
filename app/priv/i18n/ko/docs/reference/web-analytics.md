%{
  title: "애널리틱스 SDK",
  summary: "수집되는 필드, 이벤트 엔드포인트, 및 Glossia 웹 분석 기반의 개인정보 보호 모델.",
  category: "참조",
  section: "analytics",
  order: 1
}
---

## 이벤트 엔드포인트

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 은 호환성을 위해 계속 이용 가능합니다. 호스팅된 스크립트는 `/v1/collect` 를 자신의 오리지널에서 파생시킵니다. 패키지 통합에서는 `endpoint` 를 명시적으로 설정해야 합니다.

`@glossia/web` SDK 에서 JSON 이벤트를 받습니다. 항상 `202 Accepted` 를 응답합니다. 알려지지 않은 도메인 또는 비록 formatting 된 페이로드도 포함되므로 SDK 가 어떤 프로젝트가 분석 데이터를 수집하는지 누설하지 않습니다.

프로젝트는 스니펫이 선언한 사이트 도메인으로 해결됩니다. `d` 이 일반적이며, 그것이 누락될 경우 서버는 `u` (페이지 URL) 의 호스트로, 다음으로 요청 `Origin`/`Referer` 로 fallback 합니다.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 문자열 | 프로젝트를 식별하는 사이트 도메인 (e.g. `example.com`). 브라우저 라이브러리에 의해 전송되며, 대체 해석이 위에서 기술되어 있습니다. |
| `n`   | 문자열 | 이벤트 이름. 기본값은 `pageview`.                          |
| `u`   | 문자열 | 페이지 URL (`location.href`).                                  |
| `r`   | 문자열 | Referrer (`document.referrer`).                              |
| `l`   | 문자열 | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `sl`  | 문자열 | 실제 페이지 언어 (`document.documentElement.lang`). 선언되지 않으면 공란입니다. |
| `al`  | 문자열 | 값 `link[rel="alternate"][hreflang]` 에서 쉼표로 구분된 번역 언어. `x-default` 제외. |
| `tz`  | 문자열 | IANA 시간대 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | 숫자 | CSS 픽셀 기준 화면 너비.                                  |
| `sid` | 문자열 | 탭별 세션 ID (sessionStorage, 클로즈 시 초기화됨).       |

엔드포인트 가 자격 증명을 받지 않기 때문에 CORS 는 (`Access-Control-Allow-Origin: *`) 으로 열려 있습니다.

## 서버에서 파생된 필드

이것은 인구에 계산되어 서버 측에 저장됩니다. 원본 IP 와 User-Agent 는 절대 저장되지 않습니다.

| 필드             | 출처        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트의 매일 회전하는 해시. 일정을 넘어 연결 불가.  |
| `country_code`    | Cloudflare / GeoIP | 신뢰할 수 있는 `CF-IPCountry` 헤더 에서 도출된 ISO 3166-1 alpha-2 코드 또는 구성된 IP GeoIP 어댑터. 둘 다 국가를 해결하지 못합니다. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자로 된 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | Referrer      | Referrer 호스트에서 `www.`/`m.`가 제거됨.                        |
| `browser_language`| 언어     | 가장 선호하는 정규화된 지역 (예: `pt-BR`).                    |
| `served_locale`   | 페이지 언어 | 정규화된 `sl`, 또는 수집되지 않은 경우 (Not reported 로 표시됨) 공란입니다. |
| `has_locale_gap`  | 연산됨      | `1` 는 방문자의 선호 언어가 프로젝트 대상, 광고 번역 (`al`), 또는 페이지 언어 (`sl`)/와 일치하지 않을 때. 누락된 선호도는 간격으로 간주하지 않습니다. |

### 클라이언트 IP 해결

사입 Peer 에서 온 요청은 Glossia 가 nginx 의 `X-Real-IP` 헤더를, 호출자 제어 첫 번째 항목인 `X-Forwarded-For` 를 사용하지 않습니다. 직접 공개 연결은 소켓 주소를 사용합니다. Hetzner 에서 로드 밸런서와 nginx 는 모두 PROXY 프로토콜을 활성화하여 로딩 밸런서 주소 대신 방문자 주소를 수신합니다. 다른 역방향 프록시도 인증된 소스로 `X-Real-IP` 를 덮어쓰고, 무제한 내부 `X-Forwarded-For` 헤더를 사용하지 않아야 합니다. 일반적인 차트의 전달 헤더 정책만으로는 이를 보장할 수 없습니다. 사입 Peer 는 신뢰할 수 있는 인프라이므로 직통 Pod 액세스를 제한합니다.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 는 `CF-Connecting-IP` 가 사입 Peer 에서 온 요청의 표준 주소를 덮어쓰도록 허용합니다. 이는 국가 헤더 신뢰 관계와 독립적으로 **기본값으로 비활성화됨**입니다. Cloudflare 이 에지나 Cloudflare 을 우회하는 요청에서 위조된 헤더를 차단했거나 인증되어야만 활성화. DNS 전용 배포는 비활성으로 유지해야 합니다. 이 주소는 또한 IP 제한 및 일일 방문자 해시의 키 역할을 합니다.

### 국가 해결

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 는 `CF-IPCountry` 빠른 경로를 활성화합니다. **기본값으로 비활성화됨**. 오리지널이 Cloudflare 배포를 인증하거나, CloudFlare 을 우회하는 요청을 거부하거나, Ingress 가 신뢰할 수 없는 헤더 복사를 제거한 경우에만 활성화. Cloudflare 의 IP Geoip 설정도 반드시 활성화해야 합니다. `CF-Connecting-IP`, `CF-Ray`, nginx 의 `use-forwarded-headers` 는 요청 자체를 인증하지 못합니다.

헤더 신뢰가 활성화되면, IP 조회나 캐시 액세스 없이 단일 유효한 ISO 국가 코드가 즉시 사용됩니다. 현재 엣지 값은 항상 캐싱 조회보다 우선합니다. 누락, 중복, 형식 오류 또는 알 수 없는 코드 (Cloudflare 의 `XX` (알 수 없음) 와 `T1` (Tor) 값을 포함) 는 구성된 GeoIP 어댑터로 되돌립니다.

MaxMind 데이터베이스가 구성되어 있지 않은 경우, 기본 조회는 `api.ipapi.is` 을 사용하며, 주 요청이 실패하거나 인식된 국가를 반환할 때 `api.country.is` 를 사용합니다. 각 요청은 재시도가 비활성화된 1 초 연결 및 응답 타임아웃을 가집니다. 두 제공자 모두에서 성공한 결과는 Cachex 에 24 시간 캐싱되며, 10 만 엔트ரி 스케줄링 크기 제한과 자동 만료 회수를 가집니다. `Cachex.fetch/3` 는 동일한 IP 의 동시 누락을 하나의 리졸버로 줄입니다. 실패는 캐싱되지 않습니다. 개인 및 예외 주소는 제공자에게 전송되지 않습니다.

### 전달 페이지 언어

이벤트가 `sl` 를 포함하지 않을 때 대시보드는 **Not reported** 를 표시합니다. 이는 오래된 추적 버전에서 수집된 이벤트 및 HTML `lang` 속성이 없는 페이지를 포함합니다. 페이지 언어는 브라우저 선호도나 URL 에서 추론되지 않습니다. 과거 이벤트는 해당 시점에 수집된 메타데이터를 유지하며, 새로운 추적 버전은 이를 수정하지 않습니다.

## 개인 정보 보호 모델

- **지속 가능한 교차 세션 식별자는 없습니다.** SDK 는 쿠키를 설치하지 않으며, 브라우저가 닫힐 때 지워지는 탭별 세션 ID 만 `sessionStorage` 에 저장합니다.
- **지문화가 없습니다.** 캔버스, WebGL, 글꼴 및 오디오 지문은 수집되지 않습니다. 일일 회전 서버 해시는 지문 없이 고유값을 제공합니다.
- **원본 식별자가 지속되지 않습니다.** IP 와 User-Agent 는 한 번 읽혀 서버 기밀 및 일일 소금과 해시된 후 버려집니다.
- **프로젝트별 범위.** 두 프로젝트에서 동일한 브라우저는 관련 없는 방문자 ID 를 생성하므로 방문자는 Glossia 고객 간에 추적될 수 없습니다.
