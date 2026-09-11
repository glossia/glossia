%{
  title: "웹 분석 설치하기",
  summary: "HTML 한 줄로 또는 npm 을 통해 사이트에 Glossia 웹 SDK 를 추가하고 로컬라이제이션 신호 수집을 시작하세요.",
  category: "사용법",
  order: 1
}
---
이 가이드는 Glossia 프로젝트의 사이트 도메인이 프로젝트 분석 설정에 구성되어 있다고 가정합니다. 수집은 해당 도메인으로 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

각 페이지에 이 스니펫을 추가하세요. 이더면 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되며 로드 시 페이지 뷰를 전송하고, SPA 에서 클라이언트 측 내비게이션 시 이후의 페이지 뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략할 수 있으므로 단일 도메인 사이트에서는 생략해도 됩니다. 커스텀 수집 엔드포인트를 사용하려면 추가해야 합니다. `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에 한 번 초기화:

```ts
import glossia from "@glossia/web";

glossia.init();
```

해당 `domain` 에서 추론됩니다 `window.location.hostname` 따라서 SDK 는 사이트에 등록한 프로젝트에 기록됩니다. 전달하여 `{ domain: "example.com" }` 재정의하려면, 예를 들어 스테징 Origin 에서 프로덕션과 동일한 프로젝트로 이벤트를 보낼 때

사용자 정의 이벤트를 기록하려면, 예를 들어 가입:

```ts
glossia.track("signup");
```

## 작동 여부를 확인하세요

1. 브라우저에서 사이트를 여세요.
2. 네트워크 탭을 열어 확인 `POST` 요청을 `/api/analytics/events` 반환되 `202 Accepted`.
3. 1 분 내에 페이지뷰가 프로젝트 분석 대시보드에 나타납니다.

## 수집되는 항목

브라우저는 페이지 URL, 리퍼러, `navigator.languages`타임존, 스크린 너비 및 탭별 세션 ID 를 포함합니다. 서버는 GeoIP 를 통해 국가 정보를 추가하고, 프로젝트의 대상 언어와 비교하여 현지화 격차를 계산합니다. 쿠키는 설정되지 않았으며, 아무것도 프렌지핑되지 않습니다.