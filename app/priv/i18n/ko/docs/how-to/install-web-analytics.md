%{
  title: "웹 분석 설치",
  summary: "사이트에 Glossia 웹 SDK 를 한 줄의 HTML 또는 npm 을 통해 추가하고 현지화 신호 수집을 시작하세요.",
  category: "사용 방법",
  order: 1
}
---
이 안내서는 Glossia 프로젝트를 보유하시고 프로젝트의 분석 설정에 사이트 도메인이 구성되어 있다고 가정합니다. 수집은 해당 도메인으로 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

이 스니펫을 모든 페이지에 추가하세요, 특히 `<head>`\`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동 초기화되어 페이지 로드 시 페이지 뷰를 전송하며, 싱글 페이지 앱의 클라이언트 측 내비게이션 시 이후의 페이지 뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략 시 기본값이 적용되므로 단일 도메인 사이트에서는 생략할 수 있습니다. 커스텀 수집 엔드포인트를 사용하려면 추가하세요 `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번만 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init();
```

해당 `domain` 에서 추론됩니다 `window.location.hostname` 따라서 SDK 는 귀하의 사이트에서 등록한 프로젝트에 기록됩니다. 전달하세요 `{ domain: "example.com" }` 오버라이드하려면, 예를 들어 스테이징 환경의 이벤트를 프로덕션과 동일한 프로젝트로 전송합니다

사용자 정의 이벤트를 기록하려면, 예를 들어 가입:

```ts
glossia.track("signup");
```

## 작동 확인

1. 브라우저에서 사이트를 여세요.
2. 네트워크 탭을 열고 확인 `POST` 요청을 `/api/analytics/events` 반환 `202 Accepted`.
3. 1 분 이내에 페이지 뷰가 프로젝트 분석 대시보드에 표시됩니다.

## 수집 항목

브라우저는 페이지 URL, referrer, `navigator.languages`, " 시간대, 화면 너비 및 탭별 세션 ID 를 전송합니다. 서버는 GeoIP 를 통해 국가 정보를 추가하고 프로젝트의 대상 언어와 비교하여 로컬라이제이션 격차를 계산합니다. 쿠키는 설정되지 않으며, 아무 것도 지문 채취되지 않습니다."