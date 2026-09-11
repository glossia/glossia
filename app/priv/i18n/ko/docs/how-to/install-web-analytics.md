%{
  title: "웹 분석 도구 설치",
  summary: "한 줄의 HTML 로 또는 npm 을 통해 Glossia 웹 SDK 를 사이트에 추가하고 로컬라이제이션 신호 수집을 시작하세요.",
  category: "사용 가이드",
  order: 1
}
---
이 가이드는 프로젝트의 분석 설정에서 사이트 도메인이 설정되어 있는 Glossia 프로젝트를 보유하고 있다고 가정합니다. 수집은 해당 도메인으로 식별되므로 키나 시크릿을 복사할 필요가 없습니다.

## 옵션 A: 스크립트 태그

이 코드를 각 페이지에 추가하세요. 가장 이상적으로는 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 로딩 시 자동으로 초기화되며 페이지 뷰를 전송하고, SPA 내 클라이언트 측 네비게이션 시 후속 페이지 뷰도 기록합니다. `data-domain` 기본값으로 `window.location.hostname` 생략할 경우 단일 도메인 사이트에서는 제거할 수 있습니다. 사용자 지정 수집 엔드포인트를 사용하려면 추가. `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번으로 초기화:

```ts
import glossia from "@glossia/web";

glossia.init();
```

는 `domain` 은 ...에서 유추되며 `window.location.hostname` 따라서 SDK 는 귀하의 사이트에 등록된 프로젝트에 기록합니다. 을/를 전달하여 `{ domain: "example.com" }` (예를 들어 스테이지 원본에서 이벤트를 프로덕션과 동일한 프로젝트로 보낼 때) 오버라이드하여

사용자 정의 이벤트를 기록하는 경우, 예를 들어 회원가입:

```ts
glossia.track("signup");
```

## 작동 확인

1. 브라우저에서 사이트를 열어보세요.
2. 네트워크 탭을 열고 확인 `POST` 요청으로 `/api/analytics/events` 반환 `202 Accepted`.
3. 1 분 이내에 페이지뷰가 프로젝트 분석 대시보드에 표시됩니다.

## 수집 내용

브라우저는 페이지 URL, referrer, `navigator.languages`시간대, 화면 너비 및 탭별 세션 ID 도 함께 전송합니다. 서버는 GeoIP 에서 국가를 추가하고 프로젝트의 대상 언어에 대비한 로컬라이제이션 격차를 계산합니다. 쿠키는 설정되지 않았으며 지문 식별 정보도 수집되지 않았습니다.