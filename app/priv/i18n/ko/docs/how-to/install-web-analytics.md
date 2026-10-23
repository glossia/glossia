%{
  title: "웹 분석 설치",
  summary: "사이트에 Glossia 웹 SDK 를 한 줄의 HTML 로 또는 npm 으로 추가하고 현지화 신호 수집을 시작하세요.",
  category: "가이드",
  section: "analytics",
  order: 1
}
---

이 가이드는 프로젝트의 분석 설정에서 사이트 도메인이 설정된 Glossia 프로젝트가 있음을 전제로 합니다. 수집은 해당 도메인으로 식별되므로 복사할 키나 시크릿은 없습니다.

## 옵션 A: 스크립트 태그

이 구문을 모든 페이지에 추가하며 `<head>` 안에 포함하는 것이 좋습니다.

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 는 자동 초기화되며 로드되면 페이지뷰를 전송하고, SPA 의 클라이언트 측 네비게이션 시 이후 페이지뷰를 기록합니다. 생략 시 `data-domain` 은 `window.location.hostname` 값으로 기본 설정되므로 단일 도메인 사이트에서는 생략할 수 있습니다. 사용자 정의 수집 엔드포인트를 사용하려면 `data-endpoint="https://collect.your-host.com"` 를 추가하세요.

사이트가 콘텐츠 보안 정책을 사용하는 경우 `https://glossia.ai` 을 `script-src` (또는 `script-src-elem` 가 존재하는 경우) 및 `connect-src` 모두에 허용하세요. 스크립트는 `/assets/glossia-web.js` 에서 로드되며 동일한 원소에서 `/v1/collect` 로 이벤트를 전송합니다.

## 옵션 B: npm

패키지를 설치하세요:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

스스로 번들에 해당 패키지를 사용할 때 수집 엔드포인트를 명시적으로 설정해야 합니다. 추론할 수 있는 호스팅된 스크립트 주소가 없기 때문입니다.

`domain` 은 `window.location.hostname` 에서 추론되므로 SDK 는 귀하의 사이트에 등록된 프로젝트에 기록합니다. 예를 들어 스테이지 원소에서 프로덕션과 같은 프로젝트에 이벤트를 보낼 경우 `{ domain: "example.com" }` 를 사용하여 오버라이드하세요.

사용자 정의 이벤트를 기록하려면 예: 회원가입:

```ts
glossia.track("signup");
```

## 도메인 검증

프로젝트의 **분석 설정** 에서 사이트 도메인을 저장하세요. **도메인 소유권 확인** 카드에는 귀하의 프로젝트에 대한 정확한 레코드 이름과 값이 표시됩니다. 도메인 제공업체에 텍스트 레코드를 추가하세요:

| 필드 | 값 |
| --- | --- |
| 형식 | `TXT` ([텍스트 레코드](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 이름 | `_glossia-verify.example.com` |
| 값 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

설정 화면에 표시된 도메인과 토큰 을 사용하세요. 일부 제공업체는 도메인을 자동으로 추가하는 경우 해당 이름에 `_glossia-verify` 만 입력하세요. 레코드를 게시한 후 **도메인 확인** 을 클릭하세요. 변경 사항에 시간이 걸릴 수 있으므로 레코드가 즉시 검색되지 않으면 다시 시도하세요.

도메인 레코드 편집이 불가능한 경우 **대체: 홈페이지 메타 태그로 검증** 을 펼치세요. 생성된 태그를 홈페이지의 `<head>` 에 복사하여 게시하세요:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

이 두 방법 모두 구성한 도메인에 대한 통제권을 증명합니다. Glossia 는 해당 도메인의 레코드 또는 홈페이지를 확인하므로, 토큰을 다른 웹사이트에 복사한다고 해서 소유권이 검증되지 않습니다. 토큰은 공개 증명이며 비밀번호가 아닙니다.

도메인이 검증되면 Glossia 는 추적 구문에서 이벤트를 기록합니다. 추적 구문 만으로는 소유권을 검증할 수 없습니다. 구성된 도메인 변경 시 다시 검증해야 합니다.

## 올바르게 작동하는지 확인하세요:

1. 브라우저에서 사이트를 엽니다.
2. 네트워크 탭을 열고 `POST` 요청이 `https://glossia.ai/v1/collect` 에 대해 `202 Accepted` 를 반환하는지 확인하세요.
3. 수집 및 처리가 완료되면 페이지뷰 는 프로젝트 대시보드의 **분석** 항목에 표시됩니다. 오버 뷰 페이지에서 실행되는 번역은 웹사이트 트래픽과 분리됩니다.

`202 Accepted` 응답은 수집기가 요청을 수신했음을 확인합니다. 알려지지 않거나 검증되지 않은 도메인 역시 허용되지만 이벤트를 기록하지 않으므로 프로젝트 분석 설정에 구성된 도메인이 검증되었는지 확인하세요.

## 수집되는 내용

브라우저 는 페이지 URL, 리퍼러,`navigator.languages`, 시간대 및 화면 폭을 전송하거나 탭별 세션 ID 를 포함합니다. 서버는 국가 (GeoIP) 를 추가하고 프로젝트의 목표 언어에 대한 현지화 격차를 계산합니다. 쿠키는 설정되지 않으며 지문화되지 않습니다.
