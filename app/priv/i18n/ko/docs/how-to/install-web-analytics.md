%{
  title: "웹 분석 설치",
  summary: "사이트에 한 줄의 HTML 또는 npm 을 통해 Glossia 웹 SDK 를 추가하고, 로컬라이제이션 신호 수집을 시작하세요.",
  category: "가이드",
  section: "애널리틱스",
  order: 1
}
---
이 가이드는 사이트 도메인이 프로젝트의 분석 설정에 설정된 Glossia 프로젝트를 가지고 있다고 가정합니다. 데이터 수집은 해당 도메인으로 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

이 코드 조각을 모든 페이지에 추가하고, 가급적이면 해당 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되어 로드 시 페이지 뷰를 전송하며, 단일 페이지 앱의 클라이언트 측 네비게이션 시 후속 페이지 뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략할 경우 기본값을 사용하므로 단일 도메인 사이트에서도 생략할 수 있습니다. 커스텀 수집 엔드포인트를 사용하려면 추가하세요 `data-endpoint="https://collect.your-host.com"`.

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

이 `domain` 에서 추론됩니다 `window.location.hostname` 따라서 SDK 는 해당 사이트의 등록된 프로젝트에 기록됩니다. 지정 `{ domain: "example.com" }` 오버라이드하려면, 예를 들어 스테이지링 오리진에서 프로덕션과 동일한 프로젝트로 이벤트를 보낼 때.

커스텀 이벤트를 기록하려면, 예를 들어 회원가입:

```ts
glossia.track("signup");
```

## 작동 여부를 확인하세요.

1. 브라우저에서 사이트를 열어보세요.
2. 네트워크 탭을 열어 확인하세요. `POST` 요청으로 `/api/analytics/events` 반환됩니다. `202 Accepted`.
3. 한 분 안에 페이지 뷰는 프로젝트의 분석 대시보드에 표시됩니다.

## 수집 데이터

브라우저는 페이지 URL, 리퍼러, `navigator.languages`, 시간대 및 화면 너비, 탭별 세션 ID 를 함께 전송합니다. 서버는 GeoIP 를 통해 국가를 추가하고 프로젝트의 목표 언어에 대한 로컬화 격차를 계산합니다. 쿠키는 설정되지 않았으며, 어떤 것도 지문화되지 않습니다.