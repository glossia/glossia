%{
  title: "Glossia 로 로그인",
  summary: "OAuth 2.1 을 사용하여 사용자의 Glossia 계정으로 애플리케이션에 로그인할 수 있습니다.",
  category: "가이드",
  order: 2
}
---
이 가이드는 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 완료 후 사용자는 Glossia 계정으로 로그인할 수 있으며, 애플리케이션은 사용자 대신 Glossia API 를 호출할 액세스 토큰을 보유하게 됩니다.

Glossia 는 **OAuth 2.1 with PKCE** (Proof Key for Code Exchange)입니다. PKCE 는 모든 클라이언트, 서버 사이드 애플리케이션을 포함하여 필수입니다.

## 1\. OAuth 애플리케이션 등록

애플리케이션 등록에는 두 가지 옵션이 있습니다:

### 옵션 A: 대시보드를 통해 (권장)

1. Glossia 로 로그인하여 계정 대시보드로 이동하세요.
2. 열어서 **API** 사이드바 섹션에서 클릭하세요 **OAuth 앱**.
3. 클릭하세요 **새 애플리케이션**.
4. 애플리케이션을 입력하세요 **이름** 및 **콜백 URL** (또한 리디렉션 URI 라고도 합니다.)
5. 클릭 **애플리케이션 생성**.

생성 후 다음 사항을 기록하여 **클라이언트 ID** 및 **클라이언트 기밀**. 기밀은 한 번만 표시됩니다. 안전하게 보관하세요.

### 옵션 B: 동적 클라이언트 등록

보내는 `POST` 요청을 `/oauth/register`:

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

## 2\. PKCE 코드 챌린지 생성

사용자를 리디렉션하기 전에 PKCE 코드 검증자 및 챌린지를 생성:

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

## 3\. 사용자를 Glossia 로 리디렉션

인가 URL 을 구성하고 사용자의 브라우저를 리디렉션:

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
| `scope` | 번호 | 공백으로 구분된 목록 [scopes](/docs/reference/apis/authentication). 생략 시 최소 액세스가 기본값입니다 |
| `state` | 권장됨 | CSRF 공격을 막기 위한 랜덤 문자열입니다. 사용자가 돌아왔을 때 일치 여부를 확인 |

사용자는 애플리케이션 이름과 요청된 스코프를 보여주는 동의 화면을 보게 됩니다. 승인 후 Glossia 는 인가 코드가 포함된 콜백 URL 로 다시 리디렉션합니다.

## 4\. 코드를 토큰으로 교환

사용자가 콜백 URL 로 다시 리디렉션되면, URL 에는 다음 내용을 포함합니다 `code` 매개변수:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

먼저 확인하세요. `state` 3 단계에서 보낸 내용과 일치하는지 확인하세요. 그런 다음 코드를 토큰으로 교환하세요:

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

두 토큰을 안전하게 저장하세요. 액세스 토큰은 API 요청에 사용됩니다. 리프레시 토큰은 현재 액세스 토큰이 만료될 때 새 액세스 토큰을 얻기 위해 사용됩니다.

## 5\. 사용자의 대리로 API 호출

액세스 토큰을 사용하여 인증된 API 요청을 보내세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 스코프는 접근할 수 있는 엔드포인트를 제한합니다. 리소스 수준의 인증도 여전히 적용됩니다 -- 예를 들어, 토큰은 `project:read` 사용자가 액세스할 수 있는 프로젝트만 읽을 수 있습니다.

## 6\. 토큰 리프레시

액세스 토큰이 만료되면 사용자가 동의 흐름을 다시 거치지 않고 리프레시 토큰을 사용하여 새 토큰을 얻어보세요.

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 토큰 회수

사용자가 앱을 연결 해제하거나 더 이상 접근이 필요하지 않을 경우 토큰을 회수하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 범위 선택

앱이 필요한 범위만 요청하세요. 일반적인 조합 몇 가지가 있습니다:

| 사용 사례 | 범위 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 전체 조직 액세스 | `user:read organization:read organization:write members:read members:write project:read project:write` |

다음 [전체 범위 참조](/docs/reference/apis/authentication) 사용 가능한 모든 범위에서

## 발견 엔드포인트

애플리케이션은 서버 메타데이터를 가져오면 자동적으로 Glossia의 OAuth 엔드포인트를 발견할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이는 다음을 포함한 JSON 문서를 반환합니다 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`및 기타 세부 사항입니다. 발견을 사용하면 통합이 엔드포인트 변경에 더 탄력적입니다.

## 오류 처리

### 인가 오류

사용자가 동의 거절하거나 인가 중 문제가 발생하면 Glossia 는 귀하의 콜백 URL 로 리디렉션하며 함께 `error` 매개변수:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

일반 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 인가 요청을 거절했습니다 |
| `invalid_request` | 요청에서 필요한 필수 매개변수가 누락되었습니다 |
| `invalid_scope` | 요청한 스코프 중 하나 이상이 유효하지 않습니다 |

### 토큰 오류

토큰 엔드포인트는 JSON 오류 응답과 함께 HTTP 400 을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 빈도 제한

OAuth 엔드포인트는 IP 당 빈도 제한이 적용됩니다. 한도를 초과하면 HTTP 429 를 수신합니다. 상세 내용을 확인하세요. [속도 제한 참조](/docs/reference/apis/authentication) 상세 내용은.

## 보안 체크리스트

프로덕션 전환 전 구현 사항이 다음 절차에 부합하는지 확인하세요:

- 프로덕션 환경에서는 콜백 URL 에 항상 HTTPS 를 사용하세요
- 검증 `state` CSRF 를 방지하기 위해 콜백의 파라미터를
- 저장된 상태에서는 토큰을 암호화하세요
- 클라이언트 측 JavaScript 또는 브라우저 URL 에서 절대 토큰을 노출하지 마십시오
- 필요한 최소한의 권한 범위를 사용하세요
- 새로고침 토큰을 사용하여 토큰 만료를 원만하게 처리하세요
- 사용자가 접속을 종료하거나 계정을 삭제할 경우 토큰을 무효화하세요