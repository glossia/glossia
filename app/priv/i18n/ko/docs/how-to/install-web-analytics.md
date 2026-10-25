%{
  title: "웹 분석 설치",
  summary: "사이트에 한 줄의 HTML 로 Glossia 웹 SDK 를 추가하거나 npm 을 통해 추가한 후 현지화 신호 수집을 시작하세요.",
  category: "가이드",
  section: "analytics",
  order: 1
}
---

이 가이드는 프로젝트의 분석 설정 중 사이트 도메인을 구성한 Glossia 프로젝트를 보유하신 것으로 가정합니다. 수집은 해당 도메인 으로 식별되므로 복사할 키 또는 시크릿은 없습니다.

## 옵션 A: 스크립트 태그

각 페이지에 이 코드 스니펫을 추가하십시오. 가능하면 `<head>` 에 위치시키세요:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 는 자동으로 초기화되어 로드 시 페이지 뷰를 보내며, SPA 의 클라이언트 측 내비게이션 시 그 후의 페이지 뷰를 기록합니다. `data-domain` 은 생략 시 `window.location.hostname` 로 기본 설정되므로 단일 도메인 사이트에서는 생략할 수 있습니다. 커스텀 수집 엔드포인트를 사용하려면 `data-endpoint="https://collect.your-host.com"` 을 추가하십시오.

사이트가 컨텐츠 보안 정책을 사용하는 경우, `script-src` (또는 `script-src-elem` 존재 시) 와 `connect-src` 모두 `https://glossia.ai` 을 허용하십시오. 스크립트는 `/assets/glossia-web.js` 에서 로드하고 동일한 오리진 에서 `/v1/collect` 으로 이벤트를 보냅니다.

## 옵션 B: npm

패키지를 설치하십시오:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번 초기화하십시오:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

자신의 번들 에서 패키지를 사용할 때 수집 엔드포인트 를 명시적으로 설정하십시오. 호스팅된 스크립트 주소가 추론될 경로가 없기 때문입니다.

`domain` 는 `window.location.hostname` 에서 추론되므로 SDK 는 당신의 사이트에 등록한 프로젝트에 대해 기록합니다. 오버라이드를 위해 `{ domain: "example.com" }` 을 전달하십시오. 예를 들어, 프로덕션 과 동일한 프로젝트에 스테이지링 오리진 에서 이벤트를 보내기 위해.

커스텀 이벤트를 기록하기 위해 (예: 회원가입):

```ts
glossia.track("signup");
```

## 도메인 확인

프로젝트의 **분석 설정** 에서 사이트 도메인을 저장하십시오. **도메인 소유권 확인** 카드에 프로젝트의 정확한 레코드 이름 과 값 이 표시됩니다. 도메인 제공업체와 함께 텍스트 레코드를 추가하십시오:

| 필드 | 값 |
| --- | --- |
| 유형 | `TXT` ([텍스트 기록](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 이름 | `_glossia-verify.example.com` |
| 값 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

설정에서 표시된 도메인 과 토큰 을 사용하십시오. 일부 제공업체 는 도메인 을 자동으로 추가하므로, 그 경우 이름 으로 오직 `_glossia-verify` 만 입력하십시오. 레코드를 게시한 후 **도메인 확인** 을 클릭하십시오. 변경사항 이 반영되기까지 시간이 걸릴 수 있으므로 기록 이 즉시 찾지 않으면 다시 시도하십시오.

도메인 기록을 수정할 수 없는 경우 **대안: 홈페이지 메타 태그로 확인** 을 펼치십시오. 생성된 태그 를 홈페이지 `<head>` 에 복사하여 게시하십시오:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

이 두 방법 모두 구성된 도메인을 제어함을 증명합니다. Glossia 는 해당 도메인의 기록 또는 홈페이지 를 확인하므로, 토큰 을 다른 웹 사이트 로 복사해도 소유권 을 확인하지 않습니다. 토큰 은 비밀번호 가 아닌 공개 증명입니다.

도메인이 확인되면 Glossia 는 추적 스니펫 에서 이벤트를 기록합니다. 스니펫 만 으로 소유권 을 확인하지 않습니다. 구성된 도메인을 변경하려면 다시 확인이 필요합니다.

## 숙작 확인

1. 브라우저 에서 사이트 를 엽니다.
2. 네트워크 탭 을 열고 `POST` 요청 이 `https://glossia.ai/v1/collect` 에 `202 Accepted` 을 반환하는지 확인하십시오.
3. 수집 및 처리 후, 페이지 뷰 는 프로젝트 대시보드 의 **분석** 아래에 나타납니다. 개요 페이지 에서 수행되는 번역은 웹 사이트 트래픽 과는 별개 입니다.

`202 Accepted` 응답 이 요청 이 수집기 에 도달했음을 확인합니다. 알려지거나 인증되지 않은 도메인 도 허용되지만 이벤트를 기록하지 않으므로, 프로젝트 분석 설정 에서 구성된 도메인이 확인되었는지 확인하십시오.

## 수집된 항목

브라우저 는 페이지 URL, 리퍼러, `navigator.languages`, 타임존, 및 화면 너비를 전송합니다. 탭 별 세션 ID 를 포함합니다. 서버 는 나라 (GeoIP) 를 추가하고 프로젝트의 목표 언어 에 대한 현지화 격차를 계산합니다. 쿠키 가 설정되지 않으며 지문 처리 (fingerprinting) 는 되지 않습니다.
