%{
  title: "인증",
  summary: "브라우저 로그인, 액세스 토큰, 및 인증 엔드포인트.",
  category: "참조",
  subcategory: "API",
  order: 1
}
---

이 페이지는 [공개 인증](https://oauth.net/2.1/)(OAuth), [코드 교환 키 증명](https://datatracker.ietf.org/doc/html/rfc7636)(PKCE), 및 [애플리케이션 프로그래밍 인터페이스](https://developer.mozilla.org/en-US/docs/Glossary/API)(API) 를 설명합니다. 아래에 링크된 프로토콜 사양은 요청 검토서 (RFC) 로 게시됩니다.

## 인증 방법

Glossia 는 브라우저 세션과 베어 토큰을 지원합니다. 베어 토큰은 아래 인증 플로우를 통해 발급되거나 [계정 토큰](/docs/reference/apis/account-tokens) 으로 생성될 수 있습니다.

### 브라우저 세션

웹 인터페이스를 통해 로그인 시 Glossia 는 세션 기반 인증을 사용합니다. GitHub, GitLab, Google 또는 구성된 조직 식별자 제공자를 통해 [Assent](https://github.com/pow-auth/assent) 라이브러리를 사용하여 인증합니다. 성공한 로그인 후 세션 쿠키가 설정되어 다음 요청에 사용됩니다.

자동 등록을 허용하기 전에 Google Workspace 또는 Okta 를 구성하고 작업 이메일 도메인을 확인하세요. 설치 및 계정 연동 요구사항을 확인하려면 [조직 로그인 구성](/docs/how-to/organization-sign-in) 을 참조하세요.

### 베어 토큰 (OAuth 2.1)

API 액세스 (예: CLI 나 기타 도구에서) 를 위해 Glossia 는 인증 코드 플로우와 PKCE 를 통해 OAuth 2.1 을 구현합니다. 클라이언트는 베어 토큰을 취득한 후 `Authorization` 헤더에 포함시킵니다:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 플로우

### 1. 동적 클라이언트 등록

클라이언트는 메타데이터로 `POST /oauth/register` 를 호출하여 등록합니다. 이는 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) 을 따릅니다.

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 는 `client_id` 와 `client_secret` 를 반환합니다. 이 예시에서 `localhost` 리디렉션은 개발 중 응용 프로그램에 속합니다. 프로덕션 응용 프로그램은 자체 안전한 콜백 주소를 등록해야 합니다.

### 2. 인증 요청

클라이언트는 PKCE 매개변수로 `/oauth/authorize` 로 사용자를 리디렉션합니다:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**모든 클라이언트에 PKCE 가 필수입니다.** 지원되는 `S256` 도약 방법은 오직 하나입니다.

### 3. 토큰 교환

사용자가 승인하면 클라이언트는 `POST /oauth/token` 에서 인증 코드로 토큰을 교환합니다:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

반응 값에는 액세스 토큰 및 선택적으로 리프레시 토큰이 포함되어 있습니다.

### 4. 토큰 새로고침

액세스 토큰이 만료되면 리프레시 토큰을 사용하세요:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

권한 범위, 멤버 접근 및 리소스 수준 검증에 대해 [인증](/docs/reference/apis/authorization) 을 참조하세요.

## 엔드포인트 발견

클라이언트가 엔드포인트를 자동으로 발견할 수 있도록 Glossia 는 표준적으로 알려진 URL 에서 메타데이터를 게시합니다.

### OAuth 인증 서버 메타데이터 (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

발급자, 엔드포인트, 지원된 스코프, 위임 유형 및 코드 도약 방법을 반환합니다.

### 보호된 리소스 메타데이터 (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

리소스 식별자, 인증 서버, 지원된 스코프 및 베어 방법을 반환합니다.

## 속도 제한

등록은 클라이언트 주소에 의해 제한됩니다. 토큰, 회수 및 정찰 요청은 클라이언트 주소와 클라이언트 식별자 모두에 의해 제한됩니다:

| 엔드포인트 | 제한 |
|----------|-------|
| `POST /oauth/register` | 1 분당 5 요청 |
| `POST /oauth/token` | 1 분당 30 요청 |
| `POST /oauth/revoke` | 1 분당 30 요청 |
| `POST /oauth/introspect` | 1 분당 30 요청 |

속도 제한 시 서버는 HTTP 429 (요청 초과) 를 반환합니다.
