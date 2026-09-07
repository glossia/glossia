%{
  title: "인증 및 권한 부여",
  summary: "Glossia 가 사용자를 인증하고 API 접근 권한을 부여하는 방법입니다.",
  category: "참조",
  subcategory: "API",
  order: 1
}
---
## 인증 방법

Glossia 는 컨텍스트에 따라 두 가지 인증 방법을 지원합니다.

### 브라우저 세션

웹 인터페이스를 통해 로그인할 때 Glossia 는 세션 기반 인증을 사용합니다. 제 3 자 제공자 (GitHub 또는 GitLab) 를 사용하여 [Assent](https://github.com/pow-auth/assent) 라이브러리를 통해 인증합니다. 성공적인 로그인 후 세션 쿠키가 설정되어 이후 요청에 사용됩니다.

### Bearer 토큰 (OAuth 2.1)

API 액세스 (예: CLI 또는 기타 도구) 를 위해 Glossia 는 OAuth 2.1 을 클라이언트 가 TCP 임표를 고 제공하고 PKCE 를 구현합니다. 클라이언트는 Bearer 토큰을 획득하고 `Authorization` 헤더에 포함합니다:

    Authorization: Bearer <access_token>

## OAuth 2.1 흐름

### 1\. 동적 클라이언트 등록

클라이언트는 메타데이터와 함께 `POST /oauth/register` 를 호출하여 자신을 등록합니다. 이는 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) 을 따릅니다.

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

서버는 `client_id` 와 `client_secret` 을 반환합니다.

### 2\. 인증 요청

클라이언트는 PKCE 매개변수를 사용하여 사용자를 `/oauth/authorize` 로 리디렉션합니다:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE 는 모든 클라이언트에 필요합니다.** `S256` 칠투 방법만 지원됩니다.

### 3\. 토큰 교환

사용자가 승인한 후 클라이언트는 `POST /oauth/token` 에서 인증 코드를 토큰으로 교환합니다:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

응답에는 액세스 토큰이 포함되어 있으며, 선택적으로 갱신 토큰도 포함될 수 있습니다.

### 4\. 토큰 갱신

액세스 토큰 만료 시 갱신 토큰을 사용하세요:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Scope

Scope 는 토큰이 수행할 수 있는 동작을 제어합니다. `object:action` 패턴을 따릅니다.

| Scope | Description |
|-------|-------------|
| `user:read` | 사용자 프로파일 정보 읽기 |
| `user:write` | 사용자 프로파일 업데이트 |
| `account:read` | 액세스 가능한 조직 계정 목록 |
| `organization:read` | 조직 세부 정보 읽기 (및 조직 목록) |
| `organization:write` | 조직 생성 또는 업데이트 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 관리자 조직 작업 |
| `members:read` | 조직 구성원 및 초장 읽기 |
| `members:write` | 조직 구성원 및 초장 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 cập tarih 중 |
| `project:admin` | 관리자 프로젝트 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 конфигурация 읽기 |
| `voice:write` | 음성 참고구 작성 |
| `voice:admin` | 관리자 음성 작업 |
| `glossary:read` | 용어 항목 읽기 |
| `glossary:write` | 용어 항목 생성 또는 업데이트 |
| `glossary:admin` | 용어 설정 관리 |

## Authorization 모델

Glossia 는 REST API 와 MCP 서버에 대해 **두 가지 계층**을 강제합니다:

1. **Scope 확인**: 액세스 토큰은 필요한 `object:action` 범위를 포함해야 합니다.
2. **리소스 수준 정책**: 현재 사용자는 특정 리소스에 대해 `Glossia.Policy` 를 통해 권한이 부여되어야 합니다.

Scope 는 토큰의 *최대* 능력을 나타냅니다. 정책 시스템은 특정 리소스에 대한 *실제* 권한을 강제합니다.

### 역할

| Role | Description |
|------|-------------|
| `self` | 자신의 리소스에 액세스하는 사용자 |
| `organization_member` | 리소스를 소유하는 조직의 구성원 |
| `organization_admin` | 리소스를 소유하는 조직의 관리자 |
| `public_account` | 계정은 공개적 (읽기 전용) |

### 역할 권한

| 범위 | 자체 | 조직 구성원 | 조직 관리자 | 공개 계정 |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | 예 | yes | yes | |
| `user:write` | 예 | | | |
| `account:read` | | yes | yes | yes |
| `organization:read` | | Yes | Yes | |
| `organization:write` | | | Yes | |
| `organization:delete` | | | Yes | |
| `organization:admin` | | | Yes | |
| `members:read` | | Yes | Yes | |
| `members:write` | | | Yes | |
| `project:read` | | Yes | Yes | Yes |
| `project:write` | | | Yes | |
| `project:admin` | | | Yes | |
| `project:delete` | | | Yes | |
| `voice:read` | | Yes | Yes | Yes |
| `voice:write` | | | Yes | |
| `voice:admin` | | | Yes | |
| `glossary:read` | | Yes | Yes | |
| `glossary:write` | | | Yes | |
| `glossary:admin` | | | Yes | |

## 엔드포인트 발견

Glossia 는 표준 잘 알려진 URL 에서 메타데이터를 게시하여 클라이언트가 엔드포인트를 자동으로 발견할 수 있습니다.

### OAuth 인증 서버 메타데이터 (RFC 8414)

    GET /.well-known/oauth-authorization-server

발행자, 엔드포인트, 지원되는 범위, 권한 부여 유형, 및 코드 도전 방식을 반환합니다.

### 보호된 리소스 메타데이터 (RFC 9728)

    GET /.well-known/oauth-protected-resource

리소스 식별자, 인증 서버, 지원되는 범위, 및 Bearer 방법을 반환합니다.

## 속도 제한

OAuth 엔드포인트는 IP 주소별로 속도 제한됩니다:

| 엔드포인트 | 한도 |
|----------|-------|
| `POST /oauth/register` | 분당 5 회 요청 |
| `POST /oauth/token` | 분당 30 회 요청 |
| `POST /oauth/revoke` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |

속도 제한이 발생하면 서버는 HTTP 429 (요청이 너무 많습니다) 를 반환합니다.