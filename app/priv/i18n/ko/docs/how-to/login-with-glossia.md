%{
  title: "Glossia 로 로그인",
  summary: "사용자가 OAuth 2.1 을 사용하여 자신의 Glossia 계정으로 애플리케이션에 로그인할 수 있습니다.",
  category: "사용 방법",
  section: "platform",
  order: 2
}
---

이 가이드는 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 이 가이드를 완료하면 사용자는 Glossia 계정으로 로그인할 수 있으며, 애플리케이션은 사용자 대신 Glossia API 를 호출할 수 있는 액세스 토큰을 보유하게 됩니다.

Glossia 는 **OAuth 2.1 과 PKCE** (코드 교환에 대한 증명 키) 를 사용합니다. PKCE 는 서버 측 애플리케이션을 포함한 모든 클라이언트에 필수입니다.

## 1. OAuth 애플리케이션 등록

애플리케이션 등록을 위해 두 가지 옵션이 있습니다:

### 옵션 A: 대시보드를 통한 (권장)

1. Glossia 로 로그인하여 계정 대시보드로 이동하세요.
2. 사이드바의 **API** 섹션을 여시고 **OAuth 앱**을 클릭하세요.
3. **새 애플리케이션**을 클릭하세요.
4. 애플리케이션 **이름** 과 **호출 URL** (리디렉션 URI 라고도 함) 을 입력하세요.
5. **앱 생성**을 클릭하세요.

생성 후 **클라이언트 ID** 와 **클라이언트 시크릿**을 기록하세요. 시크릿은 한 번만 보이기 때문에 안전하게 저장하세요.

### 옵션 B: 동적 클라이언트 등록

`POST` 요청을 `/oauth/register` 로 보내세요:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

응답에는 `client_id` 과 `client_secret` 가 포함됩니다.

## 2. PKCE 코드 챌린지 생성

사용자를 리디렉션하기 전에 PKCE 코드 검증자와 챌린지를 생성하세요:

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

인증 URL 을 구축하고 사용자의 브라우저를 리디렉션하세요:

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

**파라미터:**

| 파라미터 | 필수 | 설명 |
|-----------|----------|-------------|
| `response_type` | 필수 | 항상 `code` |
| `client_id` | 필수 | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | 필수 | 등록한 콜백 URL 과 일치해야 합니다 |
| `code_challenge` | 필수 | PKCE 코드 챌린지 (S256) |
| `code_challenge_method` | 필수 | 항상 `S256` |
| `scope` | 선택 | 공백으로 구분된 [스코프](/docs/reference/apis/authorization) 목록. 생략한 경우 액션 스코프는 부여되지 않습니다 |
| `state` | 권장 | CSRF 공격을 방지할 무작위 문자열입니다. 사용자가 복귀할 때 일치하는지 확인하세요 |

사용자는 요청된 스코프와 애플리케이션 이름이 표시되는 동의 화면을 볼 것입니다. 승인을 한 후 Glossia 는 인증 코드를 포함하여 호출 URL 로 리디렉션합니다.

## 4. 코드를 토큰으로 교환

사용자가 호출 URL 로 리디렉션되면 URL 에 `code` 파라미터가 포함됩니다:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

먼저 `state` 가 3 단계에서 보낸 내용과 일치하는지 확인하세요. 다음 코드를 토큰으로 교환하세요:

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

반응:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

두 토큰을 안전하게 저장하세요. 액세스 토큰은 API 요청에 사용됩니다. 리프레시 토큰은 현재 토큰이 만료되었을 때 새로운 액세스 토큰을 얻는 데 사용됩니다.

## 5. 사용자를 대신하여 API 호출

액세스 토큰을 사용하여 인증된 API 요청을 보내세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 스코프는 액세스할 수 있는 엔드포인트를 제한합니다. 리소스 수준 인증은 여전히 적용됩니다. 예를 들어, `project:read` 이 있는 토큰은 사용자가 액세스할 수 있는 프로젝트 만 읽을 수 있습니다.

## 6. 토큰 새로고침

액세스 토큰이 만료되면, 동의 프로세스를 다시 거치지 않고 리프레시 토큰으로 새 토큰을 획득하세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 토큰 회수

사용자가 앱을 연결 해제하거나 더 이상 액세스가 필요하지 않을 경우 토큰을 회수하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 스코프 선택

애플리케이션이 필요한 스코프만 요청하세요. 자주 사용되는 조합 예는 다음과 같습니다:

| 사용 사례 | 스코프 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 조직 리소스 관리 | `user:read organization:read organization:write members:read members:write project:read project:write` |

제공 가능한 모든 스코프에 대한 [스코프 참조](/docs/reference/apis/authorization)를 참조하세요.

## 디커버리 엔드포인트

애플리케이션은 서버 메타데이터를 조회하여 Glossia 의 OAuth 엔드포인트를 자동으로 디커버리할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이 응답에는 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` 및 기타 세부 사항이 포함된 JSON 문서가 있습니다. 디스커버리를 사용하면 엔드포인트 변경에 대해 통합이 더욱 견고해질 것입니다.

## 오류 처리

### 인 eyes 오류

사용자가 동의를 거부하거나 인증 중 오류가 발생할 경우, Glossia 는 호출 URL 로 `error` 파라미터를 포함하여 리디렉션합니다:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

일반 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 인증 요청을 거절했습니다. |
| `invalid_request` | 요청에 필수 파라미터가 누락되었습니다. |
| `invalid_scope` | 요청된 스코프 중 하나 이상이 유효하지 않습니다. |

### 토큰 오류

토큰 엔드포인트는 JSON 오류 본문과 함께 HTTP 400 을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 속도 제한

OAuth 엔드포인트는 IP 당 속도 제한됩니다. 제한을 초과하면 HTTP 429 를 받습니다. 자세한 내용은 [속도 제한 참조](/docs/reference/apis/authentication)를 참조하세요.

## 보안 체크리스트

프로덕션 으로 이동하기 전에 구현이 다음 관행을 따르는지 확인하세요:

- 프로덕션 호출 URL 에서 항상 HTTPS 를 사용하세요
- CSRF 를 방지하기 위해 호출에서 `state` 파라미터를 검증해야 합니다
- 저장된 토큰을 암호화하세요
- 클라이언트 측 JavaScript 나 브라우저 URL 에서 토큰을 노출하지 마세요.
- 필요한 최소 스코프만 사용하세요
- 리프레시 토큰으로 토큰 만료를 유연하게 처리하세요
- 사용자가 연결 해제하거나 계정을 삭제할 경우 토큰을 회수하세요
