%{
  title: "Glossia 로 로그인",
  summary: "OAuth 2.1 을 통해 Glossia 계정으로 앱에 로그인할 수 있습니다.",
  category: "사용 가이드",
  order: 2
}
---
이 가이드는 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 가이드를 마치면 사용자는 Glossia 계정으로 로그인할 수 있고, 애플리케이션은 사용자 대신 Glossia API 를 호출하기 위한 액세스 토큰을 보유하게 됩니다.

Glossia 는 **OAuth 2.1 with PKCE** (코드 교환을 위한 증명 키)입니다. PKCE 는 모든 클라이언트 (서버 사이드 애플리케이션 포함) 에 필수입니다.

## 1\. OAuth 애플리케이션 등록

애플리케이션 등록용 두 가지 옵션이 있습니다:

### 옵션 A: 대시보드를 통한 등록 (권장)

1. Glossia 에 로그인하여 계정 대시보드로 이동하세요.
2. 열어서 **API** 사이드바 섹션에서 클릭하세요 **OAuth 앱**۔
3. 클릭하세요 **새 애플리케이션**۔
4. 애플리케이션을 입력해 **이름** 및 **콜백 URL** (또한 리디렉션 URI 라고도 함).
5. 클릭 **애플리케이션 생성**.

생성 후에는, **Client ID** 및 **Client secret**. 이 값은 한 번만 표시되므로 안전하게 저장하세요.

### 옵션 B: 동적 클라이언트 등록

보내야 `POST` 요청을 `/oauth/register`：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

반응에는 `client_id` 및 `client_secret`.

## 2\. PKCE 코드 Challenge 생성

사용자를 리디렉션하기 전에 PKCE 코드 검증자 및 Challenge 를 생성하세요.

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

## 3\. Glossia 로 사용자 리디렉션

인증 URL 을 구축하고 사용자의 브라우저로 리디렉션하세요.

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
| `code_challenge_method` | 예 | 항상 `S256` |
| `scope` | 없음 | 공백으로 구분된 목록의 | [범위](/docs/reference/apis/authentication)기본값은 생략 시 최소 접근 권한으로 적용됩니다. |
| `state` | 권장 | CSRF 공격을 예방하기 위한 임의 문자열입니다. 사용자가 돌아왔을 때 일치함을 확인해야 합니다. |

사용자는 애플리케이션 이름과 요청된 범위가 표시된 동의 화면을 보게 됩니다. 승인 후 Glossia 는 인증 코드를 포함해 콜백 URL 로 되돌아갑니다.

## 4\. 코드를 토큰으로 교환

사용자가 다시 콜백 URL 로 리디렉션되면, URL 에 포함됩니다. `code` 매개변수:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

먼저, 해당 값이 `state` 3 단계에서 보낸 내용과 일치합니다. 그런 다음 코드를 토큰으로 교환하세요:

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

두 토큰을 안전하게 보관하세요. 액세스 토큰은 API 요청에 사용됩니다. 현재 토큰이 만료되었을 때 새로운 액세스 토큰을 취득하기 위해 리프레시 토큰이 사용됩니다.

## 5\. 사용자를 대신하여 API 호출

액세스 토큰을 사용하여 인증된 API 요청을 수행하세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 범위는 접근할 수 있는 엔드포인트를 제한합니다. 리소스 레벨 권한 부여도 여전히 적용됩니다 - 예를 들어, 해당 토큰은 `project:read` 사용자가 접근할 수 있는 프로젝트만 읽을 수 있습니다.

## 6\. 토큰 갱신

액세스 토큰이 만료되면, 사용자가 다시 동의 플로우를 거치지 않도록 리프레시 토큰을 사용하여 새로운 토큰을 발급하세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 토큰 취소

사용자가 앱 연결을 해제하거나 더 이상 접근 권한이 필요하지 않은 경우 토큰을 취소하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 범위 선택

애플리케이션이 필요한 범위만 요청하세요. 일반적인 조합 몇 가지가 있습니다.

| 사용 사례 | 범위 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 전체 조직 접근 | `user:read organization:read organization:write members:read members:write project:read project:write` |

다음에 [전체 권한 참조 확인](/docs/reference/apis/authentication) 사용 가능한 모든 범위에 대해.

## 탐지 엔드포인트

애플리케이션은 서버 메타데이터를 가져와서 Glossia 의 OAuth 엔드포인트를 자동으로 발견할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이는 다음을 포함한 JSON 문서를 반환합니다 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, 및 기타 세부 사항. 탐지를 사용하면 엔드포인트 변경에도 견고한 통합을 유지할 수 있습니다.

## 오류 처리

### 권한 오류

사용자가 동의에 거부하거나 권한 중 문제가 발생하는 경우, Glossia 는 귀하의 콜백 URL 로 다음 `error` 파라미터:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

일반적인 오류 코드:

| 오류 | 설명 |
|-------|---------|
| `access_denied` | 사용자가 권한 요청을 거절했습니다 |
| `invalid_request` | 필수 매개 변수가 누락되었습니다 |
| `invalid_scope` | 요청한 범위 중 하나 이상이 유효하지 않습니다 |

### 토큰 오류

토큰 엔드포인트는 HTTP 400 과 JSON 오류 본문을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 속도 제한

OAuth 엔드포인트는 IP 별 속도 제한이 적용됩니다. 한도를 초과하면 HTTP 429 응답을 받습니다. 보십시오 [요청 제한 참조](/docs/reference/apis/authentication) 자세한 내용은.

## 보안 체크리스트

프로덕션 배포 전 구현 사항이 다음 관행을 따르는지 확인하세요:

- 프로덕션 환경의 콜백 URL 에는 항상 HTTPS 를 사용해야 합니다
- 검증: `state` 매개변수를 확인하여 CSRF 를 방지
- 저장된 토큰 은 암호화되어 있어야 합니다
- 클라이언트 사이드 JavaScript 나 브라우저 URL 에서 토큰을 노출하지 마세요
- 필요한 최소한의 scope 만 사용하세요
- 리프레시 토큰을 사용하여 토큰 만료를 자연스럽게 처리하세요
- 사용자가 연결을 끊거나 계정을 삭제할 때 토큰을 회수하세요