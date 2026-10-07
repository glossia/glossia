%{
  title: "웹 분석도구 설치",
  summary: "Glossia 웹 SDK 를 HTML 한 줄로 또는 npm 으로 사이트에 추가하여 현지화 신호를 수집하기 시작하세요.",
  category: "가이드",
  section: "analytics",
  order: 1
}
---
이 가이드는 프로젝트 애널리틱스 설정에 사이트 도메인이 구성된 Glossia 프로젝트를 가정합니다. 컬렉션은 해당 도메인으로 식별되므로 복사할 키나 시크릿이 없습니다.

## 옵션 A: 스크립트 태그

이 스니펫을 모든 페이지에 추가하세요. 최적 위치에 `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 가 자동으로 초기화되며, 로드 시 페이지뷰를 전송하고, 싱글 페이지 앱의 클라이언트 사이드 내비게이션 시 후속 페이지뷰를 기록합니다. `data-domain` 기본값은 `window.location.hostname` 생략 가능하므로 단일 도메인 사이트에서도 제거할 수 있습니다. 사용자 지정 컬렉션 엔드포인트를 사용하려면 추가하세요 `data-endpoint="https://collect.your-host.com"`.

사이트에 콘텐츠 보안 정책이 적용되면 허용 `https://glossia.ai` 양쪽 모두 `script-src` (또는 `script-src-elem` 존재하는 경우) 그리고 `connect-src`. 스크립트는 에서 로드됩니다 `/assets/glossia-web.js` 및 이벤트를 전송합니다 `/v1/collect` 동일한 출처에서.

## 옵션 B: npm

패키지 설치:

```bash
npm install @glossia/web
```

애플리케이션 진입점에 한 번 초기화하세요:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

자신만의 번들로 이 패키지를 사용할 때는 수집 엔드포인트를 명시적으로 설정해야 합니다. 호스팅된 스크립트 주소를 통해 이를 추론할 수 없기 때문입니다.

`domain` 자동으로 추론됩니다 `window.location.hostname` 따라서 SDK 는 사이트에서 등록한 프로젝트에 기록됩니다. 지정한 경우 `{ domain: "example.com" }` 덮어쓰려면, 예를 들어 스테이징 환경의 이벤트를 프로덕션과 동일한 프로젝트로 보내는 경우

맞춤형 이벤트를 기록하려면, 예를 들어 가입:

```ts
glossia.track("signup");
```

## 도메인 확인

프로젝트에서 **분석 설정**사이트 도메인을 저장하세요. **도메인 소유권 확인** 카드는 프로젝트에 대한 정확한 레코드 이름과 값을 표시합니다. 도메인 제공업체에 텍스트 레코드를 추가하세요:

| 필드 | 값 |
| --- | --- |
| 유형 | `TXT` ([텍스트 레코드](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 이름 | `_glossia-verify.example.com` |
| 값 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

설정에서 표시된 도메인과 토큰을 사용하세요. 일부 제공자는 도메인을 자동으로 추가하므로, 해당 경우 해당 값만 입력하세요 `_glossia-verify` 이름과 같습니다. 레코드를 게시한 후 클릭 **도메인 확인**. 변경 사항이 적용될 때까지 시간이 걸릴 수 있으므로, 즉시 레코드가 표시되지 않으면 다시 시도하세요.

도메인 레코드를 편집할 수 없는 경우 펼치세요 **대안: 홈페이지 메타 태그로 소유권 확인**. 생성된 태그를 해당...에 복사하세요 `<head>` 홈페이지의 해당 부분에 복사하고 게시하세요:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

두 가지 방법 모두 설정된 도메인의 관리권을 증명합니다. Glossia 는 해당 도메인의 레코드 또는 홈페이지를 확인하므로, 해당 토큰을 다른 웹사이트에 복사하면 소유권 검증이 되지 않습니다. 토큰은 공개된 증빙 자료일 뿐 비밀번호가 아닙니다.

도메인이 검증되면 Glossia 는 귀하의 추적 스니펫에서 이벤트를 기록합니다. 스니펫만으로는 소유권을 검증할 수 없습니다. 설정된 도메인을 변경하려면 다시 검증이 필요합니다.

## 작동 확인하기

1. 브라우저에서 사이트를 여세요.
2. 네트워크 탭을 열어 확인하려는 `POST` 요청 `https://glossia.ai/v1/collect` 반환 `202 Accepted`.
3. 수집 및 처리 후 페이지 뷰는 아래에 나타납니다. **분석** 프로젝트 대시보드에서. 개요 페이지에서 실행되는 번역은 웹사이트 트래픽과 분리됩니다.

한 `202 Accepted` 응답은 요청이 수집기에 도달했음을 확인합니다. 알려지지 않거나 검증되지 않은 도메인도 허용되지만 이벤트는 기록되지 않으므로, 설정된 도메인이 프로젝트의 분석 설정에서 인증되었음을 확인해 주세요.

## 수집되는 정보

브라우저는 페이지 URL, 리퍼러, `navigator.languages`, 타임존, 화면 너비 및 탭별 세션 ID를 보냅니다. 서버는 GeoIP 를 통해 국가를 추가하고 프로젝트의 목표 언어에 따른 로컬라이제이션 격차를 계산합니다. 쿠키는 설정되지 않으며, 지문 식별되지 않습니다.