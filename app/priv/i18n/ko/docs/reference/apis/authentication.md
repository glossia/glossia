%{
  title: "인증",
  summary: "브라우저 로그인, 액세스 토큰 및 인증 엔드포인트.",
  category: "참조",
  subcategory: "API",
  order: 1
}
---

이 페이지는 [오픈 인증](https://oauth.net/2.1/) (OAuth), [코드 교환을 위한 증명 키](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), 및 [애플리케이션 프로그래밍 인터페이스](https://developer.mozilla.org/en-US/docs/Glossary/API) (API) 를 설명합니다. 아래에 연결된 프로토콜 규정은 의견 요청 (RFC) 으로 출판됩니다.

## 인증 방법

Glossia 는 브라우저 세션과 Bearer 토큰을 지원합니다. Bearer 토큰은 아래 인증 흐름을 통해 발급하거나 [계정 토큰](/docs/reference/apis/account-tokens) 으로 만들 수 있습니다.

### 브라우저 세션

웹 인터페이스를 통해 로그인할 때 Glossia 는 세션 기반 인증을 사용합니다. GitHub, GitLab, Google, 또는 구성된 조직 인증 제공자를 통해 [Assent](https://github.com/pow-auth/assent) 라이브러리를 사용하여 인증합니다. 성공적인 로그인 후 세션 쿠키가 설정되어 이후 요청에 사용됩니다.

조직은 Google Workspace 또는 Okta 를 구성하고 자동 등록을 허용하기 전에 업무 이메일 도메인을 확인해야 합니다. 설정 및 계정 연결 요구 사항에 대해 [조직 로그인 구성](/docs/how-to/organization-sign-in) 을 참조하십시오.

### Bearer 토큰 (OAuth 2.1)

CLI 나 다른 도구 등 API 액세스를 위해 Glossia 는 인증 코드 흐름과 PKCE 와 함께 OAuth 2.1 을 구현합니다. 클라이언트는 Bearer 토큰을 얻고 `Authorization` 헤더에 포함합니다:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 흐름

### 1. 클라이언트 동적 등록

메타데이터를 함께 `POST /oauth/register` 하며 클라이언트는 자신을 등록합니다. 이는 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) 을 따릅니다.

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 는 `client_id` 과 `client_secret` 를 반환합니다. 이 예의 `localhost` 리디렉션은 개발 도중인 애플리케이션입니다. 프로덕션 애플리케이션은 자신의 안전한 콜백 주소를 등록해야 합니다.

### 2. 인증 요청

클라이언트는 PKCE 매개변수들을 통해 `/oauth/authorize` 로 사용자를 리디렉션합니다:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**모든 클라이언트에 PKCE 가 필수입니다.** `S256` 챌린지 방법만 지원합니다.

### 3. 토큰 교환

사용자가 승인한 후, 클라이언트는 `POST /oauth/token` 에서 인증 코드를 토큰으로 교환합니다:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

응답에는 액세스 토큰과 선택적으로 리프레시 토큰이 포함되어 있습니다.

### 4. 토큰 갱신

액세스 토큰이 만료되면 리프레시 토큰을 사용하십시오:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

[인가](/docs/reference/apis/authorization) 를 참조하여 권한 범주, 멤버 액세스, 및 리소스 수준의 확인을 확인하십시오.

## 발견 엔드포인트

Glossia 는 표준 잘 알려진 URL 에서 메타데이터를 공개하여 클라이언트가 엔드포인트를 자동으로 발견할 수 있게 합니다.

### OAuth 인증 서버 메타데이터 (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

발행자, 엔드포인트, 지원되는 권한 범위, 부여 타입, 및 코 챌린지 방법을 반환합니다.

### 보호된 리소스 메타데이터 (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

리소스 식별자, 인증 서버, 지원되는 권한 범위, 및 Bearer 방법을 반환합니다.

## 속도 제한

등록은 클라이언트 주소로 제한됩니다. 토큰, 해지, 및 인스펙션 요청은 클라이언트 주소와 클라이언트 식별자 모두로 제한됩니다:

| 엔드포인트 | 제한 |
|----------|-------|
| `POST /oauth/register` | 분당 5 회 요청 |
| `POST /oauth/token` | 분당 30 회 요청 |
| `POST /oauth/revoke` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |

속도 제한되었을 때, 서버는 HTTP 429 (요청이 너무 많습니다) 를 반환합니다.
