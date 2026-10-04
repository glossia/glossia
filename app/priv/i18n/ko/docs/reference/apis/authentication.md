%{
  title: "인증",
  summary: "브라우저 로그인, 액세스 토큰 및 인증 엔드포인트.",
  category: "참고문서",
  subcategory: "API",
  order: 1
}
---
이 페이지는 설명합니다 [Open Authorization](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), 및 [애플리케이션 프로그래밍 인터페이스](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). 아래 링크된 프로토콜 규격은 의견 요청서 (RFC) 형식으로 출판됩니다.

## 인증 방법

Glossia 는 브라우저 세션과 Bearer 토큰을 지원합니다. Bearer 토큰은 아래 인증 흐름을 통해 발급하거나 [계정 토큰](/docs/reference/apis/account-tokens).

### 브라우저 세션

웹 인터페이스를 통해 로그인하면 Glossia 는 세션 기반 인증을 사용합니다. GitHub, GitLab, Google, 또는 구성된 조직 식별 제공자를 사용하여 [Assent](https://github.com/pow-auth/assent) 라이브러리를 사용합니다. 인증에 성공한 후 세션 쿠키가 설정되어 이후 요청에 사용됩니다.

조직은 자동 등록을 허용하기 전에 Google Workspace 또는 Okta 를 구성하고 근무 이메일 도메인을 확인해야 합니다. 참조 [조직 로그인 구성](/docs/how-to/organization-sign-in) 설정 및 계정 연결 요구 사항에 대해.

### Bearer 토큰 (OAuth 2.1)

API 액세스 (예를 들어 CLI 또는 기타 도구), Glossia 는 authorization code flow 와 PKCE 를 사용하는 OAuth 2.1 을 구현합니다. 클라이언트는 Bearer 토큰을 획득하고 이를 포함하여 `Authorization` 헤더:

    Authorization: Bearer <access_token>

## OAuth 2.1 플로우

### 1\. 동적 클라이언트 등록

클라이언트는 호출하여 등록합니다. `POST /oauth/register` 해당 메타데이터와 함께. 이는 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 는 반환합니다 `client_id` 그리고 `client_secret`. 이 `localhost` 이 예시의 리디렉션은 개발 중에는 애플리케이션에 속합니다. 프로덕션 애플리케이션은 자체 보안 콜백 주소를 등록해야 합니다.

### 2\. 인증 요청

클라이언트는 사용자를 리디렉션합니다. `/oauth/authorize` PKCE 매개변수로:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**모든 클라이언트에서 PKCE 가 필요합니다.** 단, `S256` 챌린지 방법은 지원됩니다.

### 3\. 토큰 교환

사용자가 승인한 후, 클라이언트는 인증 코드로 토큰을 교환하여 다음 주소에서 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

응답에는 액세스 토큰 이 포함되며 선택적으로 리프레시 토큰 이 포함됩니다.

### 4\. 토큰 리프레시

액세스 토큰 이 만료되면 리프레시 토큰 을 사용하십시오:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

자세히 [권한 부여](/docs/reference/apis/authorization) 권한 범위, 멤버 액세스, 및 리소스 수준의 확인을 위해.

## 발견 엔드포인트

Glossia 는 표준 공개 URL 에 메타데이터를 게시하여 클라이언트가 자동으로 엔드포인트를 발견할 수 있습니다.

### OAuth 인증 서버 메타데이터 (RFC 8414)

    GET /.well-known/oauth-authorization-server

발급자, 엔드포인트, 지원 스코프, 권한 부여 유형, 및 코드 챌린지 방법을 반환합니다.

### 보호된 리소스 메타데이터 (RFC 9728)

    GET /.well-known/oauth-protected-resource

리소스 식별자, 인증 서버, 지원 스코프, 및 Bearer 방식을 반환합니다.

## 속도 제한

등록은 클라이언트 주소에 의해 제한됩니다. 토큰, 회수, 및 심층 조회 요청은 클라이언트 주소와 클라이언트 식별자 모두에 의해 제한됩니다:

| 엔드포인트 | 한도 |
|----------|-------|
| `POST /oauth/register` | 1 분당 5 회 |
| `POST /oauth/token` | 1 분당 30 회 |
| `POST /oauth/revoke` | 1 분당 30 회 |
| `POST /oauth/introspect` | 1 분당 30 회 |

요청이 제한될 경우 서버는 HTTP 429 (Too Many Requests) 를 반환합니다.