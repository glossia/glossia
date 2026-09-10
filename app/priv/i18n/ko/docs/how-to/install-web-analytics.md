%{
  title: "웹 분석 설치",
  summary: "한 줄의 HTML 또는 npm 을 통해 Glossia 웹 SDK 를 사이트에 추가하여 로케일화 신호 수집을 시작하세요.",
  category: "사용 가이드",
  order: 1
}
---
이 가이드는 프로젝트의 분석 설정에 사이트 도메인이 구성된 Glossia 프로젝트를 전제로 합니다. 수집은 해당 도메인을 통해 식별되므로 키나 시크릿을 복사할 필요가 없습니다.

## 옵션 A: 스크립트 태그

이 스니펫을 모든 페이지에 추가하세요. 최적의 위치는 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되어 로드 시 페이지뷰를 전송하며, 싱글 페이지 앱의 클라이언트 측 네비게이션 시 이후 페이지뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략될 경우, 단일 도메인 사이트에도 적용할 수 있습니다. 커스텀 수집 엔드포인트를 사용하려면 추가하세요. `data-endpoint="https://collect.your-host.com"`.

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

, `domain` 에서 유추되며, `window.location.hostname` 따라서 SDK 는 사이트에 등록되어 있는 프로젝트에 대해 기록합니다. 전달하여 `{ domain: "example.com" }` 오버라이드하거나, 예를 들어 스테이지 서버에서 온 이벤트를 프로덕션과 같은 프로젝트로 전송하려면.

사용자 정의 이벤트를 기록하려면, 예를 들어 회원가입:

```ts
glossia.track("signup");
```

## 작동 확인

1. 브라우저에서 사이트 열기.
2. 네트워크 탭을 열고 확인을 `POST` 요청 에 `/api/analytics/events` 반환됩니다. `202 Accepted`.
3. 1 분 이내에 페이지 뷰가 프로젝트 분석 대시보드에 표시됩니다.

## 수집 데이터

브라우저는 페이지 URL, 리퍼러, `navigator.languages`타임존, 화면 너비 및 탭별 세션 ID가 추가됩니다. 서버는 GeoIP 를 통해 국가 정보를 추가하고 프로젝트의 표적 언어에 대한 지역화 격차를 계산합니다. 쿠키가 설정되지 않으며 어떤 정보도 지문 처리되지 않습니다.