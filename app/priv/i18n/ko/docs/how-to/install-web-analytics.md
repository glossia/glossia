%{
  title: "웹 분석 설치",
  summary: "HTML 한 줄 또는 npm 을 통해 사이트에 Glossia 웹 SDK 를 추가하고 로컬라이제이션 신호 수집을 시작하세요.",
  category: "사용법",
  section: "analytics",
  order: 1
}
---

이 가이드는 프로젝트의 분석 설정에서 사이트 도메인이 구성된 Glossia 프로젝트를 보유하고 있다고 가정합니다. 수집은 해당 도메인에 의해 식별되므로 복사할 키나 시크릿은 없습니다.

## 옵션 A: 스크립트 태그

각 페이지에 이 스니펫을 추가하세요. (`<head>` 안에 배치하여 주시면 됩니다.)

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 는 자동으로 초기화되어 로드 시 페이지 뷰를 보내며, SPA 의 클라이언트 측 네비게이션 시 이후의 페이지 뷰를 기록합니다. `data-domain` 은 생략하면 `window.location.hostname` 로 기본값이므로, 단일 도메인 웹사이트에서는 제거할 수 있습니다. 사용자 정의 수집 엔드 포인트를 사용하려면 `data-endpoint="https://collect.your-host.com"` 를 추가하세요.

사이트가 콘텐츠 보안 정책을 사용하는 경우, `script-src` 와 `connect-src` 모두에서 `https://glossia.ai` 을 허용해야 합니다. (`script-src-elem` 가 있을 때는 해당 항목도 포함해야 합니다). 스크립트는 `/assets/glossia-web.js` 에서 로딩되며 동일한 원소에서 이벤트를 `/v1/collect` 에 전송합니다.

## 옵션 B: npm

패키지를 설치하세요:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번만 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

앱 리소스 번들 (bundle) 에서 패키지를 사용할 때는 자신을 추론할 수 있는 호스팅된 스크립트 주소가 없기 때문에, 컬렉션 엔드 포인트를 명시적으로 설정해야 합니다.

`domain` 는 `window.location.hostname` 에서 추론되므로 SDK 는 사이트에 등록한 프로젝트에 대한 기록을 남깁니다. 예를 들어, 스테이징 호스트에서 이벤트를 프로덕션과 같은 프로젝트를 보낼 때 오버라이드하려면 `{ domain: "example.com" }` 를 전달하세요.

자신이 정의한 이벤트, 예를 들어 가입 처리를 기록하려면:

```ts
glossia.track("signup");
```

## 도메인 확인

프로젝트의 **분석 설정** 에서 사이트 도메인을 저장하세요. **도메인 소유권 확인** 카드에는 프로젝트에 대한 정확한 기록명과 값이 표시됩니다. 도메인 제공업체를 통해 텍스트 레코드를 추가하세요:

| 필드 | 값 |
| --- | --- |
| 유형 | ``TXT`` ([텍스트 레코드](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 이름 | `_glossia-verify.example.com` |
| 값 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

설정 버전에서 표시한 도메인과 토큰을 사용하세요. 일부 제공업체는 도메인을 자동으로 추가합니다. 그런 경우 이름으로 `_glossia-verify` 만 입력하면 됩니다. 기록을 게시한 후 **도메인 확인** 을 클릭하세요. 변경 사항이 적용되려면 시간이 걸릴 수 있으므로 기록을 즉시 찾지 못하면 다시 시도하세요.

도메인 기록을 편집할 수 없는 경우, **대안: 홈페이지 메타 태그로 확인** 을 확장하세요. 생성된 태그를 홈페이지 `<head>` 에 복사하여 게시하세요:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

이 두 방식 모두 설정된 도메인에 대한 소유권을 통제할 수 있음을 증명합니다. Glossia 는 해당 도메인의 기록 또는 홈페이지를 확인하므로, 도메인汤姆 토큰을 타 사이트로 복사해도 소유권 확인이 되지 않습니다. 이 토큰은 공개 식별 자료이며 비밀번호가 아닙니다.

도메인이 확인되면 Glossia 는 추적 스크립트에서 이벤트를 기록합니다. 스크립트만으로는 소유권을 확인하지 않습니다. 설정된 도메인을 변경하려면 다시 확인이 필요합니다.

## 작동 여부 확인

1. 브라우저에서 אתר网站上
2. 네트워크 탭을 열고 `https://glossia.ai/v1/collect` 에Beautiful `POST` 요청이 `202 Accepted` 를 반환하는지 확인하세요.
3. 수집 및 계단 처리 후 페이지 뷰는 프로젝트 대시보드의 **분석** 하단에 나타납니다. 개요 페이지에서 실행되는 번역 작업은 웹 트래픽과는 별도로 처리됩니다.

`202 Accepted` 응답은 요청이 수집기에 도달했음을 확인합니다. 알려지지 않거나 확인되지 않은 도메인도 승인되지만 이벤트가 기록되지 않으므로, 프로젝트의 분석 설정에서 구성된 도메인이 확인되었는지 확인하세요.

## 수집되는 항목

브라우저는 페이지 URL, 리퍼러, `navigator.languages`, 타임존, 화면 너비 및 탭별 세션 ID 를 전송합니다. 서버는 GeoIP 를 통해 국가를 추가하고 프로젝트 대상 언어 대비 현지화 격차를 계산합니다. 쿠키는 설정되지 않으며 사용자는 식별됩니다.
