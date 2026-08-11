%{
  title: "웹 분석 설치",
  summary: "HTML 한 줄 또는 npm을 통해 사이트에 Glossia 웹 SDK를 추가하고 현지화 신호 수집을 시작합니다.",
  category: "how-to",
  order: 1
}
---
이 가이드에서는 프로젝트의 분석 설정에 사이트 도메인이 구성된 Glossia 프로젝트가 있다고 가정합니다. 수집은 해당 도메인으로 식별되므로 복사할 키나 비밀 값이 없습니다.

## 옵션 A: 스크립트 태그

모든 페이지의 `<head>`에 다음 코드 조각을 추가하는 것이 좋습니다.

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

소프트웨어 개발 키트는 자동으로 초기화되고, 페이지가 로드될 때 페이지 조회를 전송하며, 단일 페이지 애플리케이션의 클라이언트 측 탐색에서 이후 페이지 조회를 기록합니다. `data-domain`를 생략하면 기본값은 `window.location.hostname`이므로 단일 도메인 사이트에서는 지정하지 않아도 됩니다. 수집 엔드포인트를 직접 호스팅하려면 `data-endpoint="https://collect.your-host.com"`를 추가합니다.

## 옵션 B: npm

패키지를 설치합니다.

```bash
npm install @glossia/web
```

애플리케이션 진입점에서 한 번 초기화합니다.

```ts
import glossia from "@glossia/web";

glossia.init();
```

`domain`은 `window.location.hostname`에서 추론되므로 소프트웨어 개발 키트는 사이트에 등록된 프로젝트에 데이터를 기록합니다. 이를 재정의하려면 `{ domain: "example.com" }`를 전달합니다. 예를 들어 스테이징 출처의 이벤트를 프로덕션과 동일한 프로젝트로 전송할 수 있습니다.

가입과 같은 사용자 지정 이벤트를 기록하려면 다음과 같이 설정합니다.

```ts
glossia.track("signup");
```

## 작동 확인

1. 브라우저에서 사이트를 엽니다.
2. 네트워크 탭을 열고 `/api/analytics/events`로 전송된 `POST` 요청이 `202 Accepted`을 반환하는지 확인합니다.
3. 1분 이내에 프로젝트의 분석 대시보드에 페이지 조회가 표시됩니다.

## 수집되는 정보

브라우저는 페이지 URL, 리퍼러, `navigator.languages`, 시간대, 화면 너비와 탭별 세션 ID를 전송합니다. 서버는 GeoIP에서 확인한 국가를 추가하고 프로젝트의 대상 언어를 기준으로 현지화 격차를 계산합니다. 쿠키를 설정하지 않으며 어떠한 디지털 지문도 생성하지 않습니다.