%{
  title: "웹 분석 설치",
  summary: "사이트에 한 줄의 HTML 로 또는 npm 을 통해 Glossia 웹 SDK 를 추가하고 현지화 신호 수집을 시작하세요.",
  category: "가이드",
  order: 1
}
---
이 가이드는 프로젝트의 분석 설정에서 사이트 도메인이 구성된 Glossia 프로젝트를 사용한다고 가정합니다. 수집은 해당 도메인으로 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

이 스니펫을 모든 페이지에 추가하세요. 바람직하게는 안에서 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

단일 페이지 앱에서 SDK 는 자동 초기화되며 로드 시 페이지 뷰를 보내고 클라이언트 사이드 내비게이션 시 이후의 페이지 뷰를 기록합니다. `data-domain` 기본값으로 `window.location.hostname` 생략 시 기본값이 적용되므로 단일 도메인 사이트에서는 이를 생략할 수 있습니다. 사용자 지정 수집 엔드포인트를 사용하려면 추가하세요. `data-endpoint="https://collect.your-host.com"`.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init();
```

이는 `domain` 에서 자동으로 유추됩니다 `window.location.hostname` 따라서 SDK 는 귀하의 사이트에서 등록한 프로젝트에 기록됩니다. 전달하세요 `{ domain: "example.com" }` 덮어쓰려면, 예를 들어 스테이징 오리진에서 프로덕션과 동일한 프로젝트로 이벤트를 보낼 경우

사용자 정의 이벤트를 기록하기 위해, 예를 들어 회원가입 시:

```ts
glossia.track("signup");
```

## 작동 여부를 확인하세요

1. 브라우저에서 사이트를 여세요.
2. 네트워크 탭을 열고 확인 `POST` 요청을 `/api/analytics/events` 반환 `202 Accepted`.
3. 1 분 이내에 페이지 뷰가 프로젝트 분석 대시보드에 나타납니다.

## 수집 항목

브라우저는 페이지 URL, 리퍼러를 보냅니다. `navigator.languages`타임존, 화면 너비, 탭별 세션 ID 를 함께 전송합니다. 서버는 GeoIP 를 통해 국가 정보를 추가하고, 프로젝트의 대상 언어와 비교하여 지역화 격차를 계산합니다. 쿠키는 설정되지 않으며 지문 정보도 수집되지 않습니다.