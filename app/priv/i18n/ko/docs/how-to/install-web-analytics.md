%{
  title: "웹 분석 설치",
  summary: "한 줄의 HTML 또는 npm 을 통해 Glossia 웹 SDK 를 사이트에 추가하고 현지화 신호를 수집하기 시작하세요.",
  category: "가이드",
  order: 1
}
---
이 가이드는 분석 설정에 사이트 도메인이 구성되어 있는 Glossia 프로젝트를 보유하고 있다고 가정합니다. 컬렉션은 해당 도메인으로 식별되므로 복사할 키 또는 시크릿은 없습니다.

## 옵션 A: 스크립트 태그

각 페이지에 이 코드 조각을 추가하세요. 특히 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되며, 로딩 시 페이지 뷰를 전송하고, 싱글 페이지 앱에서 클라이언트 측 내비게이션 시 이후의 페이지 뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략할 경우 단일 도메인 사이트에서도 적용 가능합니다. 사용자 정의 컬렉션 엔드포인트를 사용하려면 추가하세요. `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번 초기화:

```ts
import glossia from "@glossia/web";

glossia.init();
```

이 `domain` 유추됩니다 `window.location.hostname` 따라서 SDK 는 사이트 등록 프로젝트에 기록합니다. 전달 `{ domain: "example.com" }` 하여 덮어씁니다. 예를 들어 staging 환경의 이벤트를 운영 환경과 같은 프로젝트로 보낼 때.

사용자 정의 이벤트를 기록하려면, 예를 들어 회원가입:

```ts
glossia.track("signup");
```

## 기능이 올바르게 작동하는지 확인

1. 브라우저에서 사이트를 여세요.
2. 네트워크 탭을 열고 확인 `POST` 요청 `/api/analytics/events` 반환 `202 Accepted`.
3. 1 분 이내에 페이지 뷰가 프로젝트 분석 대시보드에 표시됩니다.

## 수집 항목

브라우저는 페이지 URL, 리퍼러를, `navigator.languages`, 시간대 및 화면 너비, 탭별 세션 ID 를 포함하며, 서버는 GeoIP 를 이용해 국가를 추가하며, 프로젝트 대상 언어에 따른 현지화 격차를 계산합니다. 쿠키가 설정되지 않으며, 아무것도 지문 식별되지 않습니다.