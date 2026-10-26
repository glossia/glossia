%{
  title: "웹 분석 설치",
  summary: "HTML 한 줄 또는 npm 을 통해 사이트 에 Glossia 웹 SDK 를 추가하고 로케일 신호 수집을 시작하세요.",
  category: "가이드",
  section: "analytics",
  order: 1
}
---

이 가이드는 프로젝트의 분석 설정 에 사이트 도메인 이 구성된 Glossia 프로젝트를 가지고 있다고 가정합니다. 수집 은 해당 도메인 으로 식별되므로 복사할 키 나 비밀 이 없습니다.

## 옵션 A: 스크립트 태그

각 페이지 에 이 코드를 추가하세요. 가급적 `<head>` 안쪽에 추가하세요:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 는 자동으로 초기화되어 로드 시 페이지 뷰 를 전송하고, SPA 의 클라이언트 측 네비게이션 시 이후 의 페이지 뷰 를 기록합니다. 생략 할 경우 `data-domain` 은 `window.location.hostname` 로 기본값 이 설정되기 때문에 단일 도메인 사이트 에서 는 생략할 수 있습니다. 커스텀 수집 엔드포인트 를 사용하려면 `data-endpoint="https://collect.your-host.com"` 을 추가하세요.

사이트 가 콘텐츠 보안 정책을 사용하는 경우, `script-src` (또는 `script-src-elem` 보다 존재할 경우) 에 `https://glossia.ai` 을 허용하고 `connect-src` 에 도 허용하세요. 스크립트는 `/assets/glossia-web.js` 에서 로드되며 동일한 오리진 에서 `/v1/collect` 로 이벤트를 전송합니다.

## 옵션 B: npm

패키지를 설치하세요:

```bash
npm install @glossia/web
```

애플리케이션 진입점 에서 한 번만 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

자신의 번들 에서 패키지를 사용할 때 추론할 사이트 주소 가 없으므로 수집 엔드포인트 를 명시적으로 설정하세요.

`domain` 은 `window.location.hostname` 에서 추론되므로 SDK 는 사이트용 등록 프로젝트 대상 에 기록합니다. 따라서 예를 들어 프로덕션 과 동일한 프로젝트로 이벤트 를 보내기 위해 `{ domain: "example.com" }` 을 전달하여 덮어써야 합니다.

커스텀 이벤트를 기록하려면 예를 들어 가입 이벤트:

```ts
glossia.track("signup");
```

## 명시적인 언어 선택 추적

방문자의 선택 과 브라우저 기본 설정 을 구분하려면 네비게이션 전에 귀하의 언어 선택기 의 사용자 행동 핸들러 에서 SDK 를 호출하세요:

```js
glossia.selectLanguage("zh-Hans");
```

`glossia.init()` 이후 불러온 SDK 에서 이 메서드 는 사용할 수 있으며, 호스팅된 스크립트를 사용하는 경우 `glossia` 전역 에서 도 사용할 수 있습니다.

대안 으로, 동계원 원-language 전환 링크 에 주석을 추가하세요:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

각 액션 마다 하나의 통합 만 사용하세요. 두 가지 모두 사용하지 마세요. 주석 처리 된 링크 는 키보드 활성화 를 포함하여 실제 사용자 활성화 를 기록합니다. 스크립트 클릭, 다운로드, 수정된 클릭, 크로스 오리진 목적지, 또는 다른 탭 또는 프레임 을 여는 링크 는 네비게이션 을 막지 않으면서 무시합니다.

SDK 는 즉시 `language_selection` 이벤트를 보내며, 이후 이벤트 에 선택된 언어 (`cl`) 를 포함합니다. 선택 사항 은 다른 선택 사항 으로 교체될 때까지 현재 탭 과 오리진 중 `sessionStorage` 에 저장됩니다. 저장소 가 사용할 수 없는 경우 페이지 언로드 전까지 유지됩니다. 리디렉트, URL, 또는 `<html lang>` 변경 에서 선택 사항 을 추론하지 않습니다.

선택 은 성공적인 네비게이션 을 기록하는 것이 아니라 의도 를 기록합니다. 브라우저 기본 설정, 실제 페이지 언어, 명시적 선택 은 별도로 유지됩니다. 수집기 는 선택 을 저장하며, 대시보드의 현재 브라우저 기반 간극 계산 은 변경되지 않습니다.

## 도메인 확인

프로젝트의 **분석 설정** 에서 사이트 도메인 을 저장하세요. **도메인 소유권 확인** 카드 에 프로젝트 의 정확한 레코드 이름 과 값 이 표시됩니다. 도메인 제공업체 와 해당 텍스트 레코드 를 추가하세요:

| 필드 | 값 |
| --- | --- |
| 유형 | `TXT` ([ 텍스트 레코드 ](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 이름 | `_glossia-verify.example.com` |
| 값 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

설정에 표시된 도메인 과 토크인 을 사용하세요. 일부 제공업체 는 도메인 을 자동으로 추가하는 경우, 해당 경우에만 `_glossia-verify` 만 이름 을 입력하세요. 레코드를 게시한 후 **도메인 확인** 을 클릭하세요. 변경 사항 이 적용될 때까지 시간이 걸릴 수 있으므로 기록 을 즉시 찾을 수 없으면 다시 시도하세요.

도메인 기록 을 편집할 수 없는 경우 **대안: 홈페이지 메타 태그 로 확인** 을 확장하세요. 생성된 태그 를 홈페이지 의 `<head>` 에 복사하고 게시하세요:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

두 가지 방법 모두 구성 도메인 에 대한 통제권 을 증명합니다. Glossia 는 해당 도메인 의 기록 또는 홈페이지 를 확인하므로 본인 의 토크인 을 다른 웹사이트 에 복사하면 소유권 을 확인하지 않습니다. 토크인 은 공개 증거이며 비밀번호 가 아닙니다.

도메인 이 확인되면 Glossia 는 추적 스니펫 에서 이벤트를 기록합니다. 스니펫 만으로는 소유권 을 확인할 수 없습니다. 구성된 도메인 을 변경하려면 다시 확인해야 합니다.

## 작동 확인

1. 브라우저 에서 귀하의 사이트를 엽니다.
2. 네트워크 탭 을 열고 `POST` 요청 을 `https://glossia.ai/v1/collect` 에 보내고 `202 Accepted` 이 반환되는지 확인하세요.
3. 수집 및 처리 후 페이지 뷰 는 프로젝트 대시보드 메뉴 **개요** 에 나타납니다. 총상 페이지 에서 실행되는 번역 작업 은 웹 사이트 트래픽 과 별도 입니다.

`202 Accepted` 응답 은 요청 이 수집기 에 도달했음을 확인합니다. 알려지지 않거나 확인되지 않은 도메인 도 허용되지만 이벤트 를 기록하지 않으므로 프로젝트 의 분석 설정 에서 구성된 도메인 이 확인되었는지 확인하세요.

## 수집 항목

브라우저 는 페이지 URL, 리퍼러, `navigator.languages` (사용자 언어), 실제 페이지 언어 (`<html lang>`), 광고된 번역 (`hreflang` 링크), 관찰했을 때 명시적으로 선택된 언어, 시차 및 화면 너비, 탭별 세션 ID 를 보냅니다. 서버 는 국가 (GeoIP) 를 추가하고 목표 언어, 광고된 번역, 실제 페이지 언어 와 비교하여 로칼라이제이션 격차 를 계산합니다. 세션 ID 와 명시적 선택 은 `sessionStorage` 에서 처리되며 쿠키 는 설정되지 않으며 지문 처리 하지 않습니다.
