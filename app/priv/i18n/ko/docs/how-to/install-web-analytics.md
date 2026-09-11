%{
  title: "웹 분석 도구 설치",
  summary: "Glossia 웹 SDK 를 한 줄의 HTML 또는 npm 으로 사이트에 추가하여 현지화 신호 수집을 시작하세요.",
  category: "사용 가이드",
  order: 1
}
---
이 가이드는 프로젝트의 분석 설정에 사이트 도메인이 구성된 Glossia 프로젝트를 갖도록 가정합니다. 해당 도메인에 의해 수집이 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A 스크립트 태그

이 코드 조각을 모든 페이지에 추가하십시오. 권장 위치는 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 는 자동으로 초기화되며 로드 시 페이지 뷰를 전송하고, SPA 에서의 클라이언트 사이드 탐색 시 이후의 페이지 뷰도 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략하면 기본값으로 작동하므로 단일 도메인 사이트에서는 생략할 수 있습니다. 커스텀 수집 엔드포인트를 사용하려면 추가하십시오 `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번만 초기화:

```ts
import glossia from "@glossia/web";

glossia.init();
```

이것은 `domain` 자동으로 유추됩니다 `window.location.hostname` 따라서 SDK 는 귀하의 사이트 등록 프로젝트에 기록합니다. 전달해 `{ domain: "example.com" }` 지정을 위해, 예를 들어 스테이징 환경에서 이벤트를 프로덕션과 동일한 프로젝트로 전송하는 경우

사용자 지정 이벤트를 기록하려면, 예를 들어 가입:

```ts
glossia.track("signup");
```

## 작동 여부를 확인하세요.

1. 사이트를 브라우저에서 여세요.
2. 네트워크 탭을 열고 확인을 위해 `POST` 요청이 `/api/analytics/events` 되돌아옵니다. `202 Accepted`.
3. 1 분 이내 프로젝트 분석 대시보드에 페이지뷰가 표시됩니다.

## 수집 정보

브라우저는 페이지 URL 및 referrer 를 보내고, `navigator.languages`, 시간대 및 화면 너비, 탭별 세션 ID 를 포함합니다. 서버는 GeoIP 를 통해 국가 정보를 추가하고 프로젝트의 대상 언어와 비교하여 현지화 치를 계산합니다. 쿠키는 설정되지 않으며 지문식이 감정되지 않습니다.