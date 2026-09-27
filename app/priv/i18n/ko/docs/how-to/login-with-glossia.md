%{
  title: "Glossia 로 로그인",
  summary: "OAuth 2.1 을 통해 사용자의 Glossia 계정으로 애플리케이션에 로그인할 수 있습니다.",
  category: "사용 방법",
  section: "플랫폼",
  order: 2
}
---
이 가이드는 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 이 가이드를 마치면 사용자는 Glossia 계정으로 로그인할 수 있으며 애플리케이션은 사용자를 대신하여 Glossia API 를 호출할 수 있는 액세스 토큰을 얻을 수 있습니다.

Glossia 는 **PKCE 를 포함한 OAuth 2.1** (코드 교환을 위한 증명 키)입니다. PKCE 는 서버측 애플리케이션을 포함하여 모든 클라이언트에 필수적입니다.

## 1\. OAuth 애플리케이션 등록

애플리케이션 등록 방법은 두 가지입니다.

### 옵션 A: 대시보드를 통해 (권장)

1. Glossia 에 로그인하여 계정 대시보드에 이동하세요.
2. 열 **API** 섹션을 왼쪽 사이드바에서 열고 클릭 **OAuth 앱**.
3. 클릭 **새 애플리케이션**.
4. 애플리케이션을 입력 **이름** 및 **캐백 URL** (리디렉션 URI 라고도 합니다.).
5. 클릭 **애플리케이션 생성**.

생성 후, 다음 사항을 확인하세요 **클라이언트 ID** 및 **클라이언트 시크릿**. 시크릿은 한 번만 표시되므로 안전하게 보관하세요.

### 옵션 B: 동적 클라이언트 등록

요청을 `POST` 보내는 `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

응답에는 다음이 포함됩니다 `client_id` 및 `client_secret`.

## 2\. PKCE 코드 챌린지 생성

사용자 리디렉션 전에 PKCE 코드 검증자 및 챌린지를 생성하세요:

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

## 3\. Glossia 로 사용자를 리디렉션

인증 URL 을 생성하고 사용자의 브라우저를 리디렉션하세요:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**매개변수:**

| 매개변수 | 필수 | 설명 |
|-----------|----------|-------------|
| `response_type` | 예 | 항상 `code` |
| `client_id` | 예 | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | 예 | 등록된 콜백 URL 과 일치해야 합니다 |
| `code_challenge` | 예 | PKCE 코드 챌린지 (S256) |
| `code_challenge_method` | 예 | 항상 | `S256` |
| `scope` | 없음 | 공백 구분된 목록 [스코프](/docs/reference/apis/authentication). 생략 시 최소 권한으로 기본값입니다 |
| `state` | 권장됨 | CSRF 공격을 방지하는 랜덤 문자열입니다. 사용자가 다시 돌아왔을 때 일치하는지 확인하세요 |

사용자는 요청한 스코프와 애플리케이션 이름이 표시된 동의 화면을 보게 됩니다. 승인을 완료하면 Glossia 는 인증 코드를 포함하여 콜백 URL 로 다시 리디렉션합니다.

## 4\. 코드를 토큰으로 교환

사용자가 다시 콜백 URL 로 리디렉션될 때, URL 은 다음을 포함합니다 `code` 매개변수:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

먼저 확인하세요. `state` 3 단계에서 보낸 내용과 일치하는지 확인한 후, 코드를 토큰으로 교환하세요:

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

두 개의 토큰을 안전하게 보관하세요. 액세스 토큰은 API 요청에 사용됩니다. 현재 토큰이 만료되면 새 액세스 토큰을 발급받기 위해 리프레시 토큰이 사용됩니다.

## 5\. 사용자를 대신해 API 호출

인증된 API 요청을 만들기 위해 액세스 토큰을 사용하세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 스코프는 접근 가능한 엔드포인트를 제한합니다. 리소스 수준의 인증도 여전히 적용됩니다 - 예를 들어, 해당 토큰은 `project:read` 사용자가 접근할 수 있는 프로젝트만 읽을 수 있습니다.

## 6\. 토큰 갱신

액세스 토큰이 만료되면, 사용자가 다시 동의 흐름으로 보내지 않고 리프레시 토큰을 사용하여 새 토큰을 받으세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 토큰 취소

사용자가 앱을 연결 해제하거나 더 이상 접근이 필요하지 않은 경우, 토큰을 취소하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 범위 선택

애플리케이션이 필요한 범위만 요청하세요. 여기에는 일반적인 조합이 있습니다:

| 사용 사례 | 범위 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 전체 조직 접근 | `user:read organization:read organization:write members:read members:write project:read project:write` |

자세한 내용은 [전체 스코프 참조](/docs/reference/apis/authentication) 사용 가능한 모든 스코프에 대해.

## Discovery 엔드포인트

애플리케이션 은 서버 메타데이터 를 가져와 Glossia 의 OAuth 엔드포인트 를 자동으로 발견할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이 는 다음을 포함하는 JSON 문서 를 반환합니다 `authorization_endpoint`이전에 재조립된 문서가 검증에 실패했습니다: 마크다운 텍스트 노드 복구가 빈 번역을 생성했습니다 `token_endpoint`다시 조립된 문서는 이전에 유효성 검사를 실패했습니다: 마크다운 텍스트 리터럴 복구는 일치하는 길이의 JSON 문자열 배열을 반환해야 합니다 `revocation_endpoint`, 및 기타 세부 사항도 있습니다. 디스커버리를 사용하면 엔드포인트 변경에도 통합이 견고해집니다.

## 오류 처리

### 인증 오류

사용자가 동의를 거부하거나 인증 중 문제가 발생하면 Glossia 는 귀하의 콜백 URL 로 리디렉션되며 다음 `error` 매개변수:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

일반 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 인증 요청을 거부했습니다 |
| `invalid_request` | 필수 매개변수가 누락되었습니다 |
| `invalid_scope` | 요청한 스코프 중 하나 이상이 유효하지 않습니다 |

### 토큰 오류

토큰 엔드포인트는 HTTP 400 과 JSON 오류 본문을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 속도 제한

OAuth 엔드포인트는 IP 별 속도 제한이 적용됩니다. 한도를 초과하면 HTTP 429 를 받습니다. 자세한 내용은 [rate limiting 참조](/docs/reference/apis/authentication) 자세한 내용은

## 보안 체크리스트

프로덕션 배포 전에 구현이 다음 권장 사항을 준수하는지 확인하세요:

- 프로덕션 환경에서는 콜백 URL 에 항상 HTTPS 를 사용하십시오
- 검증할 `state` 파라미터를 콜백에서 확인하여 CSRF 를 방지하십시오
- 저장 시 토큰을 암호화하십시오
- 클라이언트 사이드 JavaScript 또는 브라우저 URL 에서 토큰을 절대 노출하지 마세요
- 필요한 최소한의 스코프만 사용하세요
- 리프레시 토큰을 사용하여 토큰 만료를 원활하게 처리하세요
- 사용자가 연결을 해제하거나 계정을 삭제할 때 토큰을 회수하세요