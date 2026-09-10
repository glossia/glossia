%{
  title: "인증 및 권한 부여",
  summary: "Glossia 가 사용자를 인증하고 API 접근 권한을 부여하는 방법입니다.",
  category: "참조",
  subcategory: "API",
  order: 1
}
---
## 인증 방법

Glossia 는 상황에 따라 두 가지 인증 방식을 지원합니다.

### 브라우저 세션

웹 인터페이스를 통해 로그인할 때, Glossia 는 세션 기반 인증을 사용합니다. GitHub 또는 GitLab 과 같은 제 3 자 제공자를 통해 인증하는 [Assent](https://github.com/pow-auth/assent) 라이브러리입니다. 성공적인 로그인 후 세션 쿠키가 설정되어 이후 요청에 사용됩니다.

### Bearer 토큰 (OAuth 2.1)

API 접근을 위해 (예: CLI 나 기타 도구로부터) Glossia 는 authorization code flow 와 PKCE 를 사용하는 OAuth 2.1 을 구현합니다. 클라이언트는 Bearer 토큰을 획득하여 이를 `Authorization` 제목:

    Authorization: Bearer <access_token>

## OAuth 2.1 흐름

### 1\. 동적 클라이언트 등록

클라이언트들은 호출하여 `POST /oauth/register` 자신의 메타데이터로 등록하며 이는 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

서버는 반환합니다 `client_id` 및 `client_secret`.

### 2\. 인증 요청

클라이언트는 사용자로 리디렉션합니다 `/oauth/authorize` PKCE 파라미터:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**모든 클라이언트에는 PKCE 가 필요합니다.** 오직 `S256` 챌린지 방법은 지원됩니다.

### 3\. 토큰 교환

사용자가 승인한 후, 클라이언트는 토큰 발급을 위해 인증 코드를 교환합니다 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

응답에는 액세스 토큰 및 선택적으로 새로고침 토큰이 포함됩니다.

### 4\. 토큰 갱신

액세스 토큰이 만료되면 새로고침 토큰을 사용하세요:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## 스코프

스코프는 토큰이 수행할 수 있는 동작을 제어합니다. 다음을 따릅니다. `object:action` 패턴.

| 범위 | 설명 |
|-------|-------------|
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 수정 |
| `account:read` | 접근 가능한 조직 계정 목록 |
| `organization:read` | 조직 세부 정보 읽기 (내 조직 목록 표시) |
| `organization:write` | 조직 생성 또는 수정 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 |
| `members:read` | 조직 구성원 및 초대 읽기 |
| `members:write` | 조직 구성원 및 초대 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 수정 |
| `project:admin` | 프로젝트 관리 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 설정 읽기 |
| `voice:write` | 음성 설정 생성 또는 업데이트 |
| `voice:admin` | 음성 관리 작업 |
| `glossary:read` | 용어 항목 읽기 |
| `glossary:write` | 용어 항목 생성 또는 업데이트 |
| `glossary:admin` | 용어 설정 관리 |

## 인증 모델

Glossia 는 강제합니다 **두 계층** REST API 와 MCP 서버에 대해:

1. **범위 확인**: 액세스 토큰은 다음 사항이 포함되어야 합니다. `object:action` SCOPE.
2. **리소스 수준의 정책**: 현재 사용자는 특정 리소스에 대한 인증을 위해 `Glossia.Policy`.

스코프는 *최대* 토큰의 권한 범위입니다. 정책 시스템은 *실제* 특정 리소스에 대한 칸삭입니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 리소스를 소유한 조직의 구성원 |
| `organization_admin` | 리소스를 소유한 조직의 관리자 |
| `public_account` | 계정은 공개 (읽기 전용) 입니다 |

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

## 엔드포인트 발견

Glossia 는 표준 및 잘 알려진 URL 에서 메타데이터를 발행하여 클라이언트가 자동으로 엔드포인트를 발견할 수 있도록 합니다.

### OAuth 인증 서버 메타데이터 (RFC 8414)

    GET /.well-known/oauth-authorization-server

발행자, 엔드포인트, 지원되는 스코프, 권한 부여 유형 및 코드 챌린지 방법을 반환합니다.

### 보호 리소스 메타데이터 (RFC 9728)

    GET /.well-known/oauth-protected-resource

리소스 식별자, 인증 서버, 지원되는 스코프 및 베어러 방법을 반환합니다.

## 속도 제한

OAuth 엔드포인트는 IP 주소당 속도 제한됩니다:

| 엔드포인트 | 한도 |
|----------|-------|
| `POST /oauth/register` | 분당 5 요청 |
| `POST /oauth/token` | 분당 30 요청 |
| `POST /oauth/revoke` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |

요청 제한 시, 서버는 HTTP 429 (요청 수 초과)를 반환합니다.