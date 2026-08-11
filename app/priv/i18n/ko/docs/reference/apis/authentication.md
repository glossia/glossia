%{
  title: "인증 및 권한 부여",
  summary: "Glossia가 사용자를 인증하고 API 접근 권한을 부여하는 방식입니다.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## 인증 방식

Glossia는 사용 환경에 따라 두 가지 인증 방식을 지원합니다.

### 브라우저 세션

웹 인터페이스에서 로그인하면 Glossia는 세션 기반 인증을 사용합니다. [Assent](https://github.com/pow-auth/assent) 라이브러리를 통해 타사 제공업체(GitHub 또는 GitLab)로 인증합니다. 로그인에 성공하면 세션 쿠키가 설정되며 이후 요청에 사용됩니다.

### 베어러 토큰 (OAuth 2.1)

명령줄 인터페이스 또는 기타 도구를 통한 API 접근의 경우 Glossia는 인증 코드 흐름과 PKCE를 사용하는 OAuth 2.1을 구현합니다. 클라이언트는 베어러 토큰을 발급받아 `Authorization` 헤더에 포함합니다.

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 흐름

### 1. 동적 클라이언트 등록

클라이언트는 메타데이터와 함께 `POST /oauth/register`을 호출하여 자체 등록합니다. 이 과정은 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)을 따릅니다.

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

서버는 `client_id` 및 `client_secret`을 반환합니다.

### 2. 권한 부여 요청

클라이언트는 PKCE 매개변수와 함께 사용자를 `/oauth/authorize`로 리디렉션합니다.

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**모든 클라이언트에 PKCE가 필요합니다.** `S256` 챌린지 방식만 지원됩니다.

### 3. 토큰 교환

사용자가 승인하면 클라이언트는 `POST /oauth/token`에서 인증 코드를 토큰으로 교환합니다.

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

응답에는 액세스 토큰과 선택적으로 새로 고침 토큰이 포함됩니다.

### 4. 토큰 새로 고침

액세스 토큰이 만료되면 새로 고침 토큰을 사용합니다.

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## 범위

범위는 토큰이 수행할 수 있는 작업을 제어합니다. `object:action` 패턴을 따릅니다.

| 범위 | 설명 |
|-------|-------------|
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 업데이트 |
| `account:read` | 접근 가능한 조직 계정 목록 조회 |
| `organization:read` | 조직 세부 정보 읽기 및 소속 조직 목록 조회 |
| `organization:write` | 조직 생성 또는 업데이트 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 수행 |
| `members:read` | 조직 구성원 및 초대 읽기 |
| `members:write` | 조직 구성원 및 초대 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 업데이트 |
| `project:admin` | 프로젝트 관리 작업 수행 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 보이스 구성 읽기 |
| `voice:write` | 보이스 구성 생성 또는 업데이트 |
| `voice:admin` | 보이스 관리 작업 수행 |
| `glossary:read` | 용어 항목 읽기 |
| `glossary:write` | 용어 항목 생성 또는 업데이트 |
| `glossary:admin` | 용어 설정 관리 |

## 권한 부여 모델

Glossia는 REST API와 MCP 서버에 대해 **두 단계**의 검사를 적용합니다.

1. **범위 검사**: 액세스 토큰에 필수 `object:action` 범위가 포함되어야 합니다.
2. **리소스 수준 정책**: 현재 사용자는 `Glossia.Policy`를 통해 해당 리소스에 대한 권한을 부여받아야 합니다.

범위는 토큰의 *최대* 역량을 나타냅니다. 정책 시스템은 특정 리소스에 대한 *실제* 권한을 적용합니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 리소스를 소유한 조직의 구성원 |
| `organization_admin` | 리소스를 소유한 조직의 관리자 |
| `public_account` | 계정이 공개 상태임(읽기 전용) |

### 역할 권한

| 범위 | self | organization_member | organization_admin | public_account |
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

Glossia는 클라이언트가 엔드포인트를 자동으로 찾을 수 있도록 표준 well-known URL에 메타데이터를 게시합니다.

### OAuth 권한 부여 서버 메타데이터(RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

발급자, 엔드포인트, 지원 범위, 권한 부여 유형 및 코드 챌린지 방식을 반환합니다.

### 보호된 리소스 메타데이터(RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

리소스 식별자, 권한 부여 서버, 지원 범위 및 베어러 방식을 반환합니다.

## 요청 속도 제한

OAuth 엔드포인트에는 IP 주소별 요청 속도 제한이 적용됩니다.

| 엔드포인트 | 제한 |
|----------|-------|
| `POST /oauth/register` | 분당 요청 5회 |
| `POST /oauth/token` | 분당 요청 30회 |
| `POST /oauth/revoke` | 분당 요청 30회 |
| `POST /oauth/introspect` | 분당 요청 30회 |

요청 속도가 제한되면 서버는 HTTP 429(요청이 너무 많음)를 반환합니다.