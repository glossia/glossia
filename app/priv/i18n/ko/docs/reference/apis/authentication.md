%{
  title: "인증 및 인가",
  summary: "Glossia 가 사용자를 인증하고 API 접근 권한을 부여하는 방법입니다.",
  category: "참고",
  subcategory: "API",
  order: 1
}
---
## 인증 방법

Glossia 는 상황에 따라 두 가지 인증 방법을 지원합니다.

### 브라우저 세션

웹 인터페이스를 통해 로그인하면 Glossia 는 세션 기반 인증을 사용합니다. 제 3 자 제공자 (GitHub 또는 GitLab) 를 통해 인증하며 사용하는 [Assent](https://github.com/pow-auth/assent) 라이브러리. 성공적인 로그인 후 세션 쿠키가 설정되며 이후 요청에 사용됩니다.

### Bearer 토큰 (OAuth 2.1)

API 액세스 (예: CLI 나 기타 도구) 를 위해 Glossia 는 인증 코드 플로우 및 PKCE 와 함께 OAuth 2.1 을 구현합니다. 클라이언트는 Bearer 토큰을 획득하고 이를 포함하여 `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1 flow

### 1\. Dynamic client registration

Clients register themselves by calling `POST /oauth/register` with their metadata. This follows [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

The server returns `client_id` 그리고 `client_secret`.

### 2\. 인가 요청

클라이언트는 사용자를 `/oauth/authorize` PKCE 매개변수로:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE 는 모든 클라이언트에서 필수입니다.** 단 `S256` 챌린지 방식만 지원됩니다.

### 3\. 토큰 교환

사용자가 승인한 후, 클라이언트는 인가 코드를 토큰으로 교환하기 위해 다음 주소에서 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

응답에는 액세스 토큰과 선택적으로 리프레시 토큰이 포함되어 있습니다.

### 4\. 토큰 갱신

액세스 토큰이 만료되면 리프레시 토큰을 사용해야 합니다:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## 스코프

스코프는 토큰이 수행할 수 있는 작업을 제어합니다. 그들은 다음 주소를 따릅니다. `object:action` 패턴.

| 범위 | 설명 |
|-------|-------------|
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 수정 |
| `account:read` | 액세스 가능한 조직 계정 목록 |
| `organization:read` | 조직 세부 정보 확인 (내 조직 목록) |
| `organization:write` | 조직 생성 또는 수정 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 |
| `members:read` | 조직 멤버 및 초대 조회 |
| `members:write` | 조직 멤버 및 초대 관리 |
| `project:read` | 프로젝트 조회 |
| `project:write` | 프로젝트 생성 또는 업데이트 |
| `project:admin` | 프로젝트 관리 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 설정 읽기 |
| `voice:write` | 음제 설정 생성 또는 업데이트 |
| `voice:admin` | 음제 관리 작업 |
| `glossary:read` | 용어사전 항목 보기 |
| `glossary:write` | 용어사전 항목 생성 또는 업데이트 |
| `glossary:admin` | 용어 설정 관리 |

## 인증 모델

Glossia 는 강제합니다 **두 레이어** REST API 와 MCP 서버를 위한:

1. **권한 범위 확인**: 액세스 토큰에는 필요한 `object:action` 권한 범위.
2. **리소스 수준의 정책**: 현재 사용자는 특정 리소스에 대해 권한을 부여받기 위해 `Glossia.Policy`.

스코프는 토큰의 최대 *최대* 기능을 나타냅니다. 정책 시스템은 실제 *실제* 특정 리소스에 대한 권한입니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 리소스를 소유한 조직의 구성원 |
| `organization_admin` | 해당 리소스를 소유한 조직의 관리자 |
| `public_account` | 계정이 공개되어 있습니다 (읽기 전용) |

### 역할 권한

| 범위 | self | organization\_member | organization\_admin | public\_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | 예 | 예 | | |
| `user:write` | 예 | | | |
| `account:read` | | 예 | 예 | 예 |
| `organization:read` | | 예 | 예 | |
| `organization:write` | | | 예 | |
| `organization:delete` | | | 예 | |
| `organization:admin` | | | 예 | |
| `members:read` | | 예 | 예 | |
| `members:write` | | | 예 | |
| `project:read` | | 예 | 예 | 예 |
| `project:write` | | | 예 | |
| `project:admin` | | | 예 | |
| `project:delete` | | | 예 | |
| `voice:read` | | 예 | 예 | 예 |
| `voice:write` | | | 예 | |
| `voice:admin` | | | 예 | |
| `glossary:read` | | 예 | 예 | |
| `glossary:write` | | | 예 | |
| `glossary:admin` | | | 예 | |

## 검색 엔드포인트

Glossia 는 표준 및 잘 알려진 URL 에서 메타데이터를 발행하여 클라이언트가 자동으로 엔드포인트를 검색할 수 있습니다.

### OAuth 인증서버 메타데이터 (RFC 8414)

    GET /.well-known/oauth-authorization-server

발급자, 엔드포인트, 지원되는 범위, 권한 부여 유형, 및 코드 도전 방법을 반환합니다.

### 보호 리소스 메타데이터 (RFC 9728)

    GET /.well-known/oauth-protected-resource

리소스 식별자, 인증서버, 지원되는 범위, 및 Bearer 방법을 반환합니다.

## 속도 제한

OAuth 엔드포인트는 IP 주소당 요청 제한됩니다:

| 엔드포인트 | 한도 |
|----------|-------|
| `POST /oauth/register` | 분당 5 요청 |
| `POST /oauth/token` | 분당 30 요청 |
| `POST /oauth/revoke` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |

요청 제한 시 서버는 HTTP 429 (요청 초과) 를 반환합니다.