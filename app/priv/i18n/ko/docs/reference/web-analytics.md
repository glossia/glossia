%{
  title: "분석 SDK",
  summary: "수집 필드, 이벤트 엔드포인트, 및 Glossia 웹 분석 기반 프라이버시 모델입니다.",
  category: "참고",
  section: "analytics",
  order: 1
}
---

## 이벤트 엔드포인트

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 는 호환성을 위해 여전히 사용 가능합니다. 호스팅 스크립트는 자本地的 기원에서 `/v1/collect` 를 유래하며, 패키지 통합은 `endpoint` 를 명시적으로 설정해야 합니다.

`@glossia/web` SDK 에서 JSON 이벤트를 수신합니다. 알려지지 않은 도메인이나 잘못된 페이로드가 있더라도 `202 Accepted` 를 항상 반환하여, SDK 가 어떤 프로젝트가 분석 데이터를 수집하는지 유출하지 않도록 합니다.

프로젝트는 스니펫이 선언한 사이트 도메인으로 결정됩니다. `d` 가 결정적입니다; 부재 시 서버는 `u` (페이지 URL) 의 호스트로 fallback 하며, 요청의 `Origin`/`Referer` 으로 fallback 합니다.

### 요청 본문

| 필드 | 타입   | 설명                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 프로젝트를 식별하는 사이트 도메인입니다 (예: `example.com`). 브라우저 라이브러리가 전송하며, fallback 해결 방법은 상단에 기술되어 있습니다. |
| `n`   | string | 이벤트 이름. 기본값은 `pageview` 입니다.                          |
| `u`   | string | 페이지 URL (`location.href`).                                  |
| `r`   | string | referrer (`document.referrer`).                              |
| `l`   | string | 브라우저 언어 (`navigator.languages.join(",")`).         |
| `sl`  | string | 실제 페이지 언어 (`document.documentElement.lang`). 명시되지 않은 경우 빈 문자열입니다. |
| `al`  | string | `link[rel="alternate"][hreflang]` 에서오는 쉼표 구분 번역 언어, `x-default` 제외. |
| `cl`  | string | 명시적으로 선택된 언어이지만 선택을 관찰하지 않았을 경우 공백입니다. SDK 는 BCP 47 태그를 정규화하며 입력을 64 문자로 제한합니다. |
| `tz`  | string | IANA 타임존 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS 픽셀의 화면 너비.                                  |
| `sid` | string | 탭별 세션 ID (sessionStorage, 닫힐 때 초기화됨).       |

CORS 는 개방되어 있습니다 (`Access-Control-Allow-Origin: *`) 엔드포인트는 자격 증명을 허용하지 않습니다.

## 명시적 언어 선택

`selectLanguage(language)` 는 이름 지정된 내보이기로, 기본 SDK 내보이기로, 또는 호스팅 스크립트의 `glossia` 글로벌 에서 제공됩니다. 초기화 후 사용자 행동 핸들러에서 호출하며, 네비게이션 전에 호출해야 합니다. 유효하지 않은 언어 태그와 초기화 이전 호출은 무시됩니다.

이 방법은 즉시 `language_selection` 이벤트를 전송합니다. 해당 `sl` 는 여전히 현재 페이지를 기술하며, 목적지는 아닙니다. 후속 이벤트는 다른 명시적 선택이 대체할 때까지 `cl` 에 포함됩니다. 관찰되지 않은 선택이 있으면 `cl` 는 빈 것입니다. 선택은 same-origin, 탭별 `sessionStorage` 에서 `__glossia_selected_language` 로 저장되는데, 저장 실패 시에는 메모리만 유지되어 소멸될 때까지 보유됩니다.

링크에 대해, `data-glossia-language="zh-Hans"` 는 신뢰할 수 있고 수정되지 않은 기본 클릭의 위임 추적을 활성화합니다 (키보드 활성화 포함). 스크립트 클릭, 이미 취소된 클릭, 다운로드, cross-origin 링크, 타겟이 다른 탭이나 프레임인 링크는 무시됩니다. 리스너는 라우터가 네비게이션하기 전에 캡처 단계에서 실행되며, 네비게이션을 방지하지 않고 동적으로 삽입된 링크도 처리합니다. 액션에는 주석 또는 API 중 하나만 사용하세요.

이는 클라이언트 보고 의도 신호이며, 네비게이션 성공의 증거가 아닙니다. URL 변경, 리디렉션, HTML 언어 변경은 선택으로 간주되지 않습니다. 선택은 `l` 또는 `sl` 를 덮쳐주지 않으며, 현재 `has_locale_gap` 또는 대시보드 배지를 변경하지 않습니다.

## 서버에서 파생된 필드

이것들은 수집 시 계산되며 서버 측으로 저장됩니다. 순수 IP 와 User-Agent 는 저장되지 않습니다.

| 필드             | 소스        | 설명                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 프로젝트에 대한 일일 회전 해시. 하루 간에 연결되지 않습니다.  |
| `country_code`    | Cloudflare / GeoIP | 신뢰할 수 있는 `CF-IPCountry` 헤더 또는 구성된 IP 지리 위치 어댑터에서 가져온 ISO 3166-1 알파 -2 코드. 둘 다 국가를 해결하지 않으면 빈 값. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, 또는 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 또는 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 또는 `unknown`.        |
| `hostname`        | 페이지 URL      | 소문자 호스트.                                                    |
| `pathname`        | 페이지 URL      | 경로 구성 요소.                                                     |
| `referrer_source` | 추적어      | 전두 `www.`/`m.` 를 제거한 추적어 호스트.                        |
| `browser_language`| 언어     | 가장 선호하는 정규화된 로케일 (예: `pt-BR`).                    |
| `served_locale`   | 페이지 언어 | 정규화된 `sl`, 만약 수집되지 않으면 빈 값. 빈 페이지 언어를 가진 행은 브라우저 언어 분류에서 제외됩니다. |
| `selected_locale` | 명시적 선택 | 누락, 형식 오류 또는 크기 초과 입력의 경우 정규화된 `cl`, 또는 빈 값. 브라우저 선호도와 페이지 언어와 별도로 저장됩니다. |
| `has_locale_gap`  | 계산      | 방문자의 선호 언어, 홍보된 번역 (`al`), 또는 페이지 언어 (`sl`) 가 `1` 와 일치하지 않을 때. 누락된 선호는 갭으로 계산되지 않습니다. |

### 클라이언트 IP 해석

사설 엔그레스 피어 에서 온 요청의 경우, Glossia 는 nginx 의 수정된 `X-Real-IP` 헤더를 사용합니다 (호출자 제어 `X-Forwarded-For` 의 첫 번째 항목 아님). 직접적인 공공 연결은 소켓 주소를 사용합니다. Hetzner 에서는 로드 밸런서와 nginx 모두 PROXY 프로토콜을 활성화해야 하며, nginx 는 로드 밸런서 주소 대신 방문자 주소를 수신해야 합니다. 기타 역 프록시 또한 인증된 소스로 `X-Real-IP` 를 덮어써야 하며, 제한 없는 인바운드 `X-Forwarded-For` 헤더를 사용하는 것이 아닙니다. 일반적으로 forwarding 헤더 정책만으로는 이를 보장할 수 없습니다. 사설 피어는 신뢰받는 인프라이므로 직접적인 포드 액세스를 제한해야 합니다.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 는 사설 엔그레스 피어 에서 온 요청의 표준 주소를 `CF-Connecting-IP` 가 덮어쓰도록 허용합니다. 국가 헤더 신뢰와 독립적으로 이는 **기본 비활성** 소스입니다. 에지가 Cloudflare 를 인증하거나 Cloudflare 를 우회하는 요청에서 위조 헤더를 제거한 후에만 활성화하세요. DNS 전용 배포는 비활성 상태를 유지해야 합니다. 이 주소는 또한 IP 속도 제한과 일일 방문자 해시의 핵심 키가 됩니다.

### 국가 해석

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 는 `CF-IPCountry` 라는 빠른 경로를 활성화합니다. 이는 **기본 비활성**입니다. origem 이 Cloudflare 를 인증하거나, Cloudflare 를 우회하는 요청을 거부하거나, 엔그레스 가 헤더의 신뢰하지 않는 복사본을 제거한 후에만 활성화하세요. Cloudflare 의 IP 지리 위치 설정도 활성화되어야 합니다. `CF-Connecting-IP`, `CF-Ray`, 및 nginx 의 `use-forwarded-headers` 는 요청을 인증하지 않습니다.

헤더 신뢰가 활성화되면, IP 조회나 캐시 액세스 없이 즉시 단일 유효한 ISO 국가 코드가 사용됩니다. 현재 에지 값은 모든 캐시 조회보다 우선합니다. 누락, 중복, 부패되거나 알 수 없는 코드 (Cloudflare 의 `XX` (알 수 없음) 와 `T1` (Tor) 값 포함) 는 구성된 지리 위치 어댑터로 대체됩니다.

구성된 MaxMind 데이터베이스가 없는 경우, fallback 조회는 `api.ipapi.is` 를 사용합니다. 기본 요청이 실패하거나 인식된 국가를 반환하지 않을 때 `api.country.is` 를 사용합니다. 각 요청은 재시도 해지된 1 초 연결 및 응답 타임아웃이 있습니다. 둘 다의 성공 결과는 Cachex 에서 24 시간 캐시되며, 100,000 엔트리 예정 크기 лимит 및 자동 만료 회수합니다. `Cachex.fetch/3` 는 동일한 IP 에 대한 동시 누락을 하나의 해결자로 병합합니다. 실패는 캐시되지 않습니다. 사설 및 예약 주소는 둘 다로 전송되지 않습니다.

### 누락된 페이지 언어

브라우저 언어 분류는 `sl` 이 없는 이벤트를 생략합니다. 이는 더 오래된 트래커 버전에서 수집된 이벤트 및 HTML `lang` 속성이 없는 페이지에 포함됩니다. 이러한 이벤트는 여전히 전체 트래픽에 기여합니다. 페이지 언어는 브라우저 선호도 또는 URL 에서 유추되지 않습니다. 기존 이벤트는 수집 당시 기록된 메타 데이터를 유지하며, 새 트래커 버전은 이를 단순히 채우지 않습니다.

## 개인정보 보호 모델

- **지속적인 크로스 세션 식별자 없음.** SDK 는 쿠키 를 설정하지 않으며, 탭별 세션 ID 와 명시적으로 선택된 언어만 `sessionStorage` 에 저장하며, 브라우저는 닫을 때 이를 지웁니다.
- **지문 수집 안 함.** 캔버스, WebGL, 글꼴, 및 오디오 지문은 수집되지 않습니다. 일일 회전 서버 해시는 그들을 사용하지 않고 고유합니다.
- **원시 식별자 저장되지 않음.** IP 와 User-Agent 는 한번 읽혀진 후 서버 비밀과 일일 소금으로 해시되어 버려집니다.
- **프로젝트 단위 범위.** 두 프로젝트의 동일한 브라우저는 관련 없는 방문자 ID 를 생성하며, 방문자는 Glossia 고객 사이에서 추적될 수 없습니다.
