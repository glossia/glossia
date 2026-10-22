%{
  title: "Glossia 로 로그인",
  summary: "OAuth 2.1 을 사용하여 Glossia 계정으로 앱에 로그인할 수 있습니다.",
  category: "가이드",
  section: "platform",
  order: 2
}
---

이 가이드에서 애플리케이션에 "Glossia 로 로그인"을 추가하는 방법을 안내합니다. 완료 시, 사용자는 Glossia 계정으로 로그인할 수 있으며, 앱은 사용자의 대위를 대신하여 Glossia API 를 호출할 수 있는 액세스 토큰을 갖게 됩니다.

Glossia 는 **OAuth 2.1 와 PKCE** (Proof Key for Code Exchange) 를 사용합니다. 모든 클라이언트, 서버 측 애플리케이션을 포함하여 PKCE 가 필수적입니다.

## 1. OAuth 애플리케이션 등록

애플리케이션을 등록하기 위한 두 가지 옵션이 있습니다:

### 옵션 A: 대시보드를 통해 (권장)

1. Glossia 로 로그인하고 계정으로 이동합니다.
2. 사이드바의 **API** 섹션을 열고 **OAuth 앱** 을 클릭합니다.
3. **새 애플리케이션** 을 클릭합니다.
4. 애플리케이션 **이름** 과 **호출 URL** (또는 리디렉션 URI) 을 입력하세요.
5. **애플리케이션 생성** 을 클릭합니다.

생성 후 **클라이언트 ID** 와 **클라이언트 기밀** 를 확인하세요. 기밀은 한 번만 표시되므로 안전하게 저장하세요.

### 옵션 B: 동적 클라이언트 등록

`POST` 요청을 `/oauth/register` 로 보냅니다:

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

사용자의 리디렉션 전에 PKCE 코드 검증자 (Verifier) 와 챌린지를 생성합니다:

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

인증 URL 을 빌드하고 사용자의 브라우저로 리디렉션합니다:

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
| `response_type` | 예 | 항상 `code` |
| `client_id` | 예 | 애플리케이션의 클라이언트 ID |
| `redirect_uri` | 예 | 등록된 호출 URL 과 일치해야 합니다. |
| `code_challenge` | 예 | PKCE 코드 챌린지 (S256) |
| `code_challenge_method` | 예 | 항상 `S256` |
| `scope` | 아니요 | 공백 구분 [스코프](/docs/reference/apis/authorization) 목록. 생략 시 어떤 액션 스후도 부여되지 않습니다. |
| `state` | 권장 | CSRF 기습 를 방지하기 위한 랜덤 문자열. 사용자가 복귀할 때 일치 여부를 확인하세요. |

사용자는 애플리케이션 이름과 요청된 스후를 보여주는 동의 화면을 볼 것입니다. 동하게 후, Glossia 는 인증 코드를 포함하여 호출 URL 로 다시 리디렉션합니다.

## 4. 코드를 토큰으로 교환

사용자가 호출 URL 로 리디렉션되면 URL 에 `code` 파라미터가 포함됩니다:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

먼저 3 번 단계에서 보낸 `state` 과 일치하는지 확인한 후 코드를 토큰으로 교환합니다:

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

응답입니다:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

두 토큰 모두 안전하게 저장하세요. 액세스 토큰은 API 요청에 사용되며, 리프레시 토큰은 현재 토큰이 만료될 때 새 액세스 토큰을 얻는 데 사용됩니다.

## 5. 사용자 명목으로 API 호출

액세스 토큰을 사용하여 인증된 API 요청을 생성하세요:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

토큰의 스코프는 접근 가능한 엔드포인트를 제한합니다. 리소스 수준의 인증도 여전히 적용됩니다 -- 예를 들어, `project:read` 에는 사용자가 접근할 수 있는 프로젝트만 읽을 수 있습니다.

## 6. 토큰 새로고침

액세스 토큰이 만료되면 사용자를 동의 흐름을 다시 통과시키지 않고 리프레시 토큰을 사용하여 새 토큰을 얻으세요:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 토큰 취소

사용자가 앱을 연결 해제하거나 더 이상 접근이 필요하지 않을 때 토큰을 취소하세요:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 스코프 선택

애플리케이션이 필요한 스코프만 요청하세요. 일반적인 조합 몇 가지를 살펴보세요:

| 사용 사례 | 스코프 |
|----------|--------|
| 사용자 프로필 읽기 | `user:read` |
| 프로젝트 및 콘텐츠 읽기 | `user:read project:read voice:read` |
| 프로젝트 관리 | `user:read project:read project:write` |
| 조직 리소스 관리 | `user:read organization:read organization:write members:read members:write project:read project:write` |

실존 가능한 모든 스코프는 [스코프 참조](/docs/reference/apis/authorization) 를 확인하세요.

## 검색 엔드포인트

애플리케이션은 서버 메타데이터를 가져오하여 Glossia 의 OAuth 엔드포인트를 자동으로 검색할 수 있습니다:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

이 요청은 `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` 및 기타 세부 사항이 포함된 JSON문서를 반환합니다. 검색을 사용하면 엔드포인트 변경에 강건한 통합을 만들 수 있습니다.

## 오류 처리

### 인증 오류

사용자가 동의를 거부하거나 인증 중 문제가 발생할 경우, Glossia 는 `error` 파라미터를 포함하여 호출 URL 로 리디렉션합니다:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

일반 오류 코드:

| 오류 | 의미 |
|-------|---------|
| `access_denied` | 사용자가 인증 요청을 거부했습니다. |
| `invalid_request` | 필수 파라미터가 누락된 요청입니다. |
| `invalid_scope` | 요청된 하나 이상의 스코프가 유효하지 않습니다. |

### 토큰 오류

토큰 엔드포인트는 JSON 오류 본문과 함께 HTTP 400 을 반환합니다:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート 제한

OAuth 엔드포인트는 IP 당 비율 제한됩니다. 제한에 도달하면 HTTP 429 를 받으실 것입니다. 자세한 내용은 [레오프라이트 제한 참조](/docs/reference/apis/authentication) 를 확인하세요.

## 보안 체크리스트

프로덕션环境优美에 들어가기 전에 구현이 다음 관행에 부합하는지 확인하세요:

- 프로덕션 환경에서 호출 URL 에 대해 항상 HTTPS 를 사용하세요
- 보안을 방지하기 위해 호출에서 `state` 파라미터를 확인하세요
- 휴면에서 암호화된 토큰을 저장하세요
- 클라이언트 측 JavaScript 나 브라우저 URL 에서 절대 토큰을 노출하지 마세요
- 애플리케이션이 필요한 최소한의 스코프만 사용하세요
- 리프레시 토큰을 사용하여 토큰 만료를 부드럽게 처리하세요
- 사용자가 앱을 연결 해제하거나 계정을 삭제할 때 토큰을 취소하세요
