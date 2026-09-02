%{
  title: "웹 분석 설치",
  summary: "웹 사이트에 Glossia 웹 SDK 를 한 줄의 HTML 또는 npm 을 통해 추가하고 현지화 신호 수집을 시작하세요.",
  category: "가이드",
  order: 1
}
---
이 가이드는 프로젝트의 분석 설정에 사이트 도메인이 설정되어 있는 Glossia 프로젝트를 보유하고 있다고 가정합니다. 수집은 그 도메인으로 식별되므로 복사해야 할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

이 코드를 각 페이지에 추가하세요. 이상적으로는 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되어 페이지 로딩 시 페이지 뷰를 전송하고, SPA 의 클라이언트 사이드 네비게이션에서 후속 페이지 뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략할 경우 사용 가능하므로 단일 도메인 사이트에는 추가하지 않아도 됩니다. 사용자 정의 수집 엔드포인트를 사용하려면 추가하세요. `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지를 설치하세요:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번만 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init();
```

해당 값은 `domain` 서에서 유추됩니다 `window.location.hostname` 따라서 SDK 는 사이트에 등록한 프로젝트에 대해 기록합니다. 다음값을 전달하여 덮어쓸 수 있습니다. 예를 들어, 스테이징 오리진에서 프로덕션과 동일한 프로젝트로 이벤트를 전송합니다. `{ domain: "example.com" }` 커스텀 이벤트를 기록하려면 (예: 가입)

작동 여부를 확인하세요

```ts
glossia.track("signup");
```

## 브라우저에서 사이트를 열어보세요

1. 네트워크 탭을 열고
2. 요청 `POST` 반환됩니다. `/api/analytics/events` . `202 Accepted`1 분 내에 페이지 뷰는 프로젝트의 분석 대시보드에 표시됩니다.
3. 수집되는 정보

## 브라우저는 페이지 URL, 리퍼러,

시간대 및 스크린 너비, 탭별 세션 ID 를 포함합니다. 서버는 GeoIP 를 통해 국가를 추가하고 프로젝트의 대상 언어에 대한 현지화 격차를 계산합니다. 쿠키는 설정되지 않으며 치환되지 않습니다. `navigator.languages`싱글 페이지 앱