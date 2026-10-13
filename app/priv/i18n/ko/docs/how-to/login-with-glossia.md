%{
  title: "Glossia 로 로그인",
  summary: "사용자가 OAuth 2.1 을 통해 자신의 Glossia 계정으로 앱에 로그인할 수 있습니다.",
  category: "사용 가이드",
  section: "platform",
  order: 2
}
---

이 가이드에서는 "Glossia 로 로그인" 기능을 애플리케이션에 추가하는 방법을 안내합니다. 이 가이드를 마치면 사용자는 Glossia 계정으로 로그인하고, 애플리케이션은 그들의 명의로 Glossia API 를 호출할 액세스 토큰을 보유하게 됩니다.

Glossia 는 **OAuth 2.1 with PKCE**(Proof Key for Code Exchange) 을 사용합니다. PKCE 는 서버 사이드 애플리케이션을 포함한 모든 클라이언트에 필요합니다.

## 1. OAuth 애플리케이션 등록

애플리케이션을 등록하기 위해 두 가지 옵션이 있습니다:

### 옵션 A: 대시보드 단을 통해 등록(권장)

1. Glossia 에 로그인하여 계정 대시보드로 이동하세요.
2. 사이드바의 **API** 섹션을 열고 **OAuth apps**를 클릭하세요.
3. **새 애플리케이션**을 클릭하세요.
4. 애플리케이션의 **name**과 **callback URL**(리다이렉트 URI 라고도 함)을 입력하세요.
5. **애플리케이션 만들기**를 클릭하세요.

생성 후, **Client ID**와 **Client secret**를 기록하세요. 신원은 한 번만 표시되므로 안전하게 보관하세요.

### 옵션 B: 동적 클라이언트 등록

`POST` 요청을 `/oauth/register` 으로 보내세요:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

응답에는 `client_id` 과 `client_secret` 이 포함됩니다.

## 2. PKCE 코드 도전책 생성

사용자를 리디렉션하기 전에 PKCE 코드 채증자와 도전책을 생성하세요:

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

## 3. 사용자를 Glossia 로 리디렉션

인증 URL 을 작성하고 사용자의 브라우저로 리디렉션하세요:

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**매개변수:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `response_type` | Yes | 항상 `code` |
| `client_id` | Yes | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | Yes | 등록된 callback URL 과 일치해야 합니다 |
| `code_challenge` | Yes | PKCE 코드 도전책(S256) |
| `code_challenge_method` | Yes | 항상 `S256` |
| `scope` | No | 공백으로 구분된 [scopes](/docs/reference/apis/authorization) 리스트. 생략된 경우 액션 스코프는 부여되지 않습니다 |
| `state` | Recommended | CSRF 공격을 방지하기 위한 무작위 문자열. 사용자가 돌아온 경우 일치하는지 확인하세요 |

사용자는 애플리케이션 이름과 요청된 스코프를 보여주는 동의 화면을 봅니다. 승인 후 Glossia 는 인증 코드가 포함된 콜백 URL 로 다시 리디렉션합니다.

## 4. 코드를 토큰으로 교환

사용자가 콜백 URL 로 다시 리디렉션되면 URL 에는 `code` 매개변수가 포함됩니다:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

먼저 `state` 이 3 단계에서 보낸 내용과 일치하는지 확인합니다. 그런 다음 코드를 토큰으로 교환하세요:

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

두 토크를 안전하게 보관하세요. 액세스 토크는 API 요청에 사용됩니다. 현재 액세스 토크가 만료될 때 리프레시 토크를 사용하여 새 액세스 토크를 얻습니다.

## 5. 사용자가 대신 API 호출하기

인증된 API 요청을 생성하기 위해 액세스 토크를 사용하세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토크의 스코프는 접근 가능한 엔드포인트를 제한합니다. 리소스 수준의 인가는 여전히 적용됩니다. 예를 들어, `project:read` 를 가진 토크는 사용자가 접근 가능한 프로젝트만 읽을 수 있습니다.

## 6. 토크 갱신하기

액세스 토크가 만료되면, 사용자가 동의 절차를 다시 거치지 않고 새 토크를 얻기 위해 리프레시 토크를 사용하세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 토크 취소하기

사용자가 앱을 연결을 해제하거나 더 이상 액세스가 필요하지 않을 때 토크를 취소하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 스코프 선택하기

애플리케이션이 필요한 스코프만 요청하세요. 일반적인 조합이 몇 가지 있습니다:

| 사용 사례 | 스코프 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리하기 | `user:read project:read project:write` |
| 조직 리소스 관리하기 | `user:read organization:read organization:write members:read members:write project:read project:write` |

사용 가능한 모든 [scopes reference](/docs/reference/apis/authorization) 를 참조하세요.

## 발견 엔드포인트

애플리케이션은 서버 메타데이터를 가져오는 방식으로 Glossia 의 OAuth 엔드포인트를 자동으로 발견할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이는 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, 및 기타 세부사항을 포함한 JSON 문서입니다. 발견을 사용하면 통합이 엔드포인트 변경에 대해 탄력적입니다.

## 오류 처리

### 인가 오류

사용자가 동의를 거부하거나 인증 문제가 발생하면 Glossia 는 `error` 매개변수가 포함된 콜백 URL 로 리디렉션합니다:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

일반적인 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 인가 요청을 거부했습니다. |
| `invalid_request` | 요청에 필요한 매개변수가 누락되었습니다. |
| `invalid_scope` | 요청된 스코프 중 하나 이상이 유효하지 않습니다. |

### 토크 오류

토크 엔드포인트는 JSON 오류 본문과 함께 HTTP 400 을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 레이트 제한

OAuth 엔드포인트는 IP 마다 레이트 제한이 적용됩니다. 제한을 초과하면 HTTP 429 를 받게 됩니다. 자세한 내용은 [rate limiting reference](/docs/reference/apis/authentication) 를 참조하세요:

## 보안 점검 목록

프로덕션 배포 전에 구현이 다음 관행을 따르는지 확인하세요:

- 프로덕션 환경에서 콜백 URL 에는 항상 HTTPS 를 사용하세요
- CSRF 를 방지하기 위해 콜백에서 `state` 매개변수를 확인하세요
- 저장 중 암호화된 상태로 토크를 보관하세요.
- 클라이언트 사이드 JavaScript 나 브라우저 URL 에서 토크를 노출하지 마세요.
- 필요한 최소한의 스코프만 사용하세요.
- 리프레시 토크를 사용하여 토크 만료 시妥善处理하세요.
- 사용자가 앱 연결을 해제하거나 계정을 삭제할 때 토크를 취소하세요.
