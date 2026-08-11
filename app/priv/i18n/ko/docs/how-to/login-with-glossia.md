%{
  title: "Glossia로 로그인",
  summary: "OAuth 2.1을 사용하여 사용자가 Glossia 계정으로 앱에 로그인할 수 있도록 설정합니다.",
  category: "how-to",
  order: 2
}
---
이 가이드는 애플리케이션에 "Glossia로 로그인" 기능을 추가하는 방법을 안내합니다. 가이드를 완료하면 사용자가 Glossia 계정으로 로그인할 수 있으며, 애플리케이션은 사용자를 대신해 Glossia API를 호출할 수 있는 액세스 토큰을 갖게 됩니다.

Glossia는 **PKCE를 사용하는 OAuth 2.1**(Proof Key for Code Exchange)을 사용합니다. 서버 측 애플리케이션을 포함한 모든 클라이언트에 PKCE가 필요합니다.

## 1. OAuth 애플리케이션 등록

애플리케이션을 등록하는 방법은 두 가지입니다.

### 옵션 A: 대시보드에서 등록(권장)

1. Glossia에 로그인하고 계정 대시보드로 이동합니다.
2. 사이드바에서 **API** 섹션을 열고 **OAuth 앱**을 클릭합니다.
3. **새 애플리케이션**을 클릭합니다.
4. 애플리케이션 **이름**과 **콜백 URL**(리디렉션 URI라고도 함)을 입력합니다.
5. **애플리케이션 생성**을 클릭합니다.

생성 후 **클라이언트 ID**와 **클라이언트 시크릿**을 기록해 두십시오. 시크릿은 한 번만 표시되므로 안전하게 보관해야 합니다.

### 옵션 B: 동적 클라이언트 등록

`POST` 요청을 `/oauth/register`에 전송합니다.

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

응답에는 `client_id` 및 `client_secret`이 포함됩니다.

## 2. PKCE 코드 챌린지 생성

사용자를 리디렉션하기 전에 PKCE 코드 검증자와 챌린지를 생성합니다.

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

## 3. 사용자를 Glossia로 리디렉션

인증 URL을 생성하고 사용자의 브라우저를 리디렉션합니다.

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

| 매개변수 | 필수 여부 | 설명 |
|-----------|----------|-------------|
| `response_type` | 예 | 항상 `code` |
| `client_id` | 예 | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | 예 | 등록된 콜백 URL과 일치해야 함 |
| `code_challenge` | 예 | PKCE 코드 챌린지(S256) |
| `code_challenge_method` | 예 | 항상 `S256` |
| `scope` | 아니요 | 공백으로 구분된 [범위](/docs/reference/apis/authentication) 목록. 생략하면 최소 액세스 권한이 기본값으로 적용됨 |
| `state` | 권장 | 사이트 간 요청 위조 공격을 방지하기 위한 임의 문자열. 사용자가 돌아왔을 때 값이 일치하는지 확인해야 함 |

사용자에게 애플리케이션 이름과 요청된 범위를 보여주는 동의 화면이 표시됩니다. 사용자가 승인하면 Glossia는 인증 코드와 함께 사용자를 콜백 URL로 다시 리디렉션합니다.

## 4. 코드를 토큰으로 교환

사용자가 콜백 URL로 다시 리디렉션되면 URL에 `code` 매개변수가 포함됩니다.

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

먼저 `state`이 3단계에서 전송한 값과 일치하는지 확인합니다. 그런 다음 코드를 토큰으로 교환합니다.

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

두 토큰을 모두 안전하게 보관하십시오. 액세스 토큰은 API 요청에 사용됩니다. 새로 고침 토큰은 현재 액세스 토큰이 만료되었을 때 새 액세스 토큰을 받는 데 사용됩니다.

## 5. 사용자를 대신해 API 호출

액세스 토큰을 사용하여 인증된 API 요청을 수행합니다.

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 범위에 따라 액세스할 수 있는 엔드포인트가 제한됩니다. 리소스 수준의 권한 부여도 계속 적용됩니다. 예를 들어 `project:read`이 있는 토큰으로는 사용자가 액세스할 수 있는 프로젝트만 읽을 수 있습니다.

## 6. 토큰 새로 고침

액세스 토큰이 만료되면 새로 고침 토큰을 사용하여 사용자가 동의 절차를 다시 거치지 않고 새 액세스 토큰을 받을 수 있습니다.

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 토큰 취소

사용자가 애플리케이션 연결을 해제하거나 더 이상 액세스가 필요하지 않으면 토큰을 취소합니다.

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 범위 선택

애플리케이션에 필요한 범위만 요청하십시오. 일반적인 조합은 다음과 같습니다.

| 사용 사례 | 범위 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 조직 전체 액세스 | `user:read organization:read organization:write members:read members:write project:read project:write` |

사용 가능한 모든 범위는 [전체 범위 참조](/docs/reference/apis/authentication)를 확인하십시오.

## 검색 엔드포인트

애플리케이션은 서버 메타데이터를 가져와 Glossia의 OAuth 엔드포인트를 자동으로 검색할 수 있습니다.

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이 요청은 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` 및 기타 세부 정보가 포함된 JSON 문서를 반환합니다. 검색 기능을 사용하면 엔드포인트가 변경되어도 통합이 안정적으로 작동합니다.

## 오류 처리

### 권한 부여 오류

사용자가 동의를 거부하거나 권한 부여 과정에서 문제가 발생하면 Glossia는 `error` 매개변수를 포함하여 콜백 URL로 리디렉션합니다.

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

일반적인 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 권한 부여 요청을 거부했습니다 |
| `invalid_request` | 요청에 필수 매개변수가 누락되었습니다 |
| `invalid_scope` | 요청한 범위 중 하나 이상이 유효하지 않습니다 |

### 토큰 오류

토큰 엔드포인트는 JSON 오류 본문과 함께 HTTP 400을 반환합니다.

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 요청 한도

OAuth 엔드포인트에는 IP별 요청 한도가 적용됩니다. 한도에 도달하면 HTTP 429 응답을 받습니다. 자세한 내용은 [요청 한도 참조](/docs/reference/apis/authentication)를 확인하십시오.

## 보안 체크리스트

프로덕션으로 전환하기 전에 구현이 다음 관행을 준수하는지 확인하십시오.

- 프로덕션 환경의 콜백 URL에는 항상 HTTPS를 사용하십시오
- 사이트 간 요청 위조를 방지하려면 콜백에서 `state` 매개변수를 검증하십시오
- 저장된 토큰을 암호화하십시오
- 클라이언트 측 JavaScript 또는 브라우저 URL에 토큰을 노출하지 마십시오
- 필요한 최소 범위만 사용하십시오
- 새로 고침 토큰을 사용하여 토큰 만료를 안정적으로 처리하십시오
- 사용자가 연결을 해제하거나 계정을 삭제하면 토큰을 폐기하십시오