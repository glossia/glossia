%{
  title: "Glossia 로 로그인",
  summary: "OAuth 2.1 을 사용하여 사용자는 자신의 Glossia 계정으로 앱에 로그인할 수 있습니다.",
  category: "사용 가이드",
  order: 2
}
---
이 가이드는 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 완료되면 사용자는 Glossia 계정으로 로그인할 수 있으며, 애플리케이션은 사용자의 대리로 Glossia API 를 호출할 수 있는 접근 토큰을 갖게 됩니다.

Glossia 는 **PKCE 를 지원하는 OAuth 2.1** (코드 교환을 위한 증명 키). PKCE 는 모든 클라이언트 (서버 측 애플리케이션 포함) 에 필요합니다.

## 1\. OAuth 애플리케이션 등록

애플리케이션을 등록하는 방법은 두 가지가 있습니다:

### 옵션 A: 대시보드를 통한 등록 (권장)

1. Glossia 로 로그인한 후 계정 대시보드에 이동하세요.
2. 열어 **API** 사이드바의 섹션에서 클릭 **OAuth 앱**.
3. 클릭 **새 애플리케이션**.
4. 애플리케이션 정보를 입력 **이름** 및 **콜백 URL** (또한 리디렉션 URI 로도 불림).
5. 클릭 **애플리케이션 생성**.

생성 후 다음 사항을 **클라이언트 ID** 및 **클라이언트 시크릿**. 시크릿은 한 번만 표시되므로 안전하게 보관하세요.

### 옵션 B: 동적 클라이언트 등록

요청을 `POST` 보내는 주소로 `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

응답에는 포함되어 있습니다 `client_id` 그리고 `client_secret`.

## 2\. PKCE 코드 도전을 생성하세요

사용자 리디렉션 전에 PKCE 코드 verifier 와 도전을 생성:

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3\. 사용자를 Glossia 로 리디렉션하세요

인증 URL 을 생성하고 사용자의 브라우저를 리디렉션:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**파라미터:**

| 파라미터 | 필수 | 설명 |
|-----------|----------|-------------|
| `response_type` | 예 | 항상 `code` |
| `client_id` | 예 | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | 예 | 등록된 콜백 URL 과 일치해야 합니다 |
| `code_challenge` | 예 | PKCE 코드 챌린지 (S256) |
| `code_challenge_method` | 예 | 항상 | `S256` |
| `scope` | 순번 | 공백으로 구분된 목록 | [scopes](/docs/reference/apis/authentication). 기본값은 생략 시 최소 접근 권한입니다 |
| `state` | 권장 | CSRF 공격을 방지하기 위한 임의 문자열입니다. 사용자가 복귀할 때 일치하는지 확인하세요 |

사용자는 애플리케이션 이름과 요청된 scopes 를 표시한 동의 화면을 볼 수 있습니다. 승인 후 Glossia 는 인증 코드를 포함하여 콜백 URL 로 다시 리디렉션합니다.

## 4\. 코드를 토큰으로 교환

사용자가 콜백 URL 로 다시 리디렉션되면 URL 에 다음이 포함되어 있습니다 `code` 매개변수:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

먼저 확인하세요 `state` 3 단계에서 보낸 것과 일치합니다. 그런 다음 코드를 토큰으로 교환하세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

응답:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

두 토크를 안전하게 저장하세요. 액세스 토크는 API 요청에 사용됩니다. 리프레시 토크는 현재 토크가 만료되었을 때 새 액세스 토크를 발급받는 데 사용됩니다.

## 5\. 사용자를 대신하여 API 호출

액세스 토크를 사용하여 인증된 API 요청을 수행하세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토크의 스코프는 접근 가능한 엔드포인트를 제한합니다. 리소스 수준의 권한 인증이 여전히 적용됩니다 -- 예를 들어, 다음 토크를 가진 `project:read` 사용자가 액세스할 수 있는 프로젝트만 읽을 수 있습니다.

## 6\. 토크 새로 고침

액세스 토크가 만료되면, 사용자를 다시 동의 흐름으로 보내지 않고 새 토크를 얻기 위해 리프레시 토크를 사용하세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 토큰 취소

사용자가 애플리케이션 연결을 해제하거나 더 이상 접근이 필요하지 않은 경우 토큰을 취소하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 스코프 선택

애플리케이션이 필요한 스코프만 요청하세요. 일반적인 조합은 다음과 같습니다:

| 용도 | 스코프 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 전체 조직 접근 | `user:read organization:read organization:write members:read members:write project:read project:write` |

전체 [적용 범위 참조](/docs/reference/apis/authentication) 모든 사용 가능한 범위에 대해

## Discovery 엔드포인트

애플리케이션은 서버 메타데이터를 가져와 자동으로 Glossia 의 OAuth 엔드포인트를 발견할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이는 다음과 같은 JSON 문서에 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`및 기타 세부 사항입니다. Discovery 를 통해 통합이 엔드포인트 변경에 견고해집니다.

## 오류 처리

### 인가 오류

사용자가 동의 거절하거나 인가 중 문제가 발생할 경우, Glossia 는 귀하의 콜백 URL 로 다음 `error` 매개변수:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

일반적인 오류 코드:

| 오류 | 설명 |
|-------|---------|
| `access_denied` | 사용자가 인가 요청을 거부했습니다 |
| `invalid_request` | 요청에 필수 매개변수가 누락되었습니다.
| `invalid_scope` | 요청한 스코프 중 하나 이상이 유효하지 않습니다.

### 토큰 오류

토큰 엔드포인트는 JSON 오류 본체를 포함하여 HTTP 400 을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 속도 제한

OAuth 엔드포인트는 IP 마다 속도 제한이 적용됩니다. 한도를 초과할 경우 HTTP 429 를 받습니다. 참조하십시오. [레이트 리미팅 참조](/docs/reference/apis/authentication) 자세한 내용은.

## 보안 체크리스트

프로덕션 배포 전에 구현이 다음 관행을 따르는지 확인하세요:

- 프로덕션 환경에서는 콜백 URL 에 항상 HTTPS 를 사용하세요
- 검증해야 하는 `state` 코백 매개변수 CSRF 를 방지하기 위해
- 저장된 토큰을 암호화된 상태로 보관하세요
- 클라이언트 사이드 JavaScript 나 브라우저 URL 에 토큰을 노출하지 마세요
- 필요한 최소한의 스코프만 사용하세요
- 리프레시 토큰을 사용하여 토큰 만료를 매끄럽게 처리하세요
- 사용자가 연결을 끊거나 계정을 삭제할 때 토큰을 철회하세요