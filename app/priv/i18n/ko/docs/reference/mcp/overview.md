%{
  title: "개요",
  summary: "모델 컨텍스트 프로토콜을 통해 Glossia 프로젝트에 코드 에이전트를 연결하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---

Glossia 는 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io)(MCP) 서버를 노출하여 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있게 합니다. 서버는 OAuth 2.1 이 PKCE 와 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 을 구현했기 때문에, 모든 MCP 호환 클라이언트가 수동 자격 증명 설정 없이 인증할 수 있습니다.

## MCP 서버가 제공하는 기능

연결 후 코딩 에이전트는 권한 범위 내에서 계정과 프로젝트를 목록으로 표시하고, 프로젝트를 생성하며, 조직 멤버와 초대장을 관리하고, 음성 및 사전 설정을 읽거나 업데이트하며, 계정 모델과 토큰을 관리할 수 있습니다.

서버는 현재 번역을 시작하거나, 수정을 시작하거나, 파일 수준의 번역 상태를 검사할 도구를 노출하지 않습니다. 사용 가능한 도구는 [도구 참조](/docs/reference/mcp) 를 확인하세요.

## 서버 URL

`https://glossia.ai/mcp` 에서 Glossia 의 호스팅 서비스에 접속하세요. Glossia 가이 엔드포인트를 운영하고 관리하므로, 연결 설정은 코딩 에이전트에서만 수행하면 됩니다.

## 인증 흐름

MCP 서버는 PKCE 와 함께 사용하는 표준 OAuth 2.1 인증 코드 플로우를 사용합니다. 수동 OAuth 클라이언트 생성이 필요 없습니다. 흐름은 다음과 같습니다:

1. 에이전트는 `https://glossia.ai/.well-known/oauth-authorization-server` 를 통해 Glossia 를 발견합니다.
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 등록합니다.
3. 로그인 및 동의를 위해 브라우저를 엽니다.
4. 승인 후 에이전트는 액세스 토큰을 받아 모든 MCP 요청에 첨부합니다.

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

[Codex 연결 가이드](https://developers.openai.com/codex/mcp) 를 따르면 `~/.codex/config.toml` 의 설정 파일에 서버를 추가하십시오:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행하십시오:

```bash
codex mcp login glossia
```

인증이 완료되면 브라우저가 열립니다. 승인 후 코덱스는 토큰을 로컬에 저장하여 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

### Claude Code

[Claude Code 연결 가이드](https://code.claude.com/docs/en/mcp) 에 문서화된 명령으로 호스팅된 서버를 추가하십시오:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Claude Code 내부에서 `/mcp` 를 실행하고 브라우저 인증 흐름을 따르세요.

### 다른 MCP 클라이언트

클라이언트는 Glossia 에서 구현된 [모델 컨텍스트 프로토콜 인증 흐름](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 을 지원해야 합니다. 연결에는 다음이 필요합니다:

- **전송**: 스트리머블 HTTP
- **발견**: 클라이언트는 OAuth 2.0 Protected Resource Metadata([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)) 를 지원해야 합니다.
- **등록**: 동적 클라이언트 등록([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **인증 흐름**: PKCE 를 사용한 인증 코드 (S256)

클라이언트 `https://glossia.ai/mcp` 로 설정하고 검색 및 등록을 자동으로 처리하게 하세요.

## 검색 엔드포인트

서버는 MCP 클라이언트가 OAuth 플로우를 시작하는 데 사용하는 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터 (엔드포인트, 지원된 그랜트 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호 리소스 메타데이터 (범위, 인증 서버) |

## 속도 제한

OAuth 엔드포인트는 남용 방지를 위해 속도 제한을 강제합니다:

| 엔드포인트 | 제한 |
|---|---|
| `POST /oauth/register` | 1 분당 5 요청 |
| `POST /oauth/token` | 1 분당 30 요청 |
| `POST /oauth/introspect` | 1 분당 30 요청 |
| `POST /oauth/revoke` | 1 분당 30 요청 |

속도 제한을 초과하면 서버는 HTTP 429 와 `Retry-After` 헤더를 반환합니다.

## 문제 해결

### 등록이 "invalid_client_metadata" 로 실패합니다

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용합니다. 공공 클라이언트 (대부분의 코딩 에이전트) 는 `"none"` 를 보내야 하며, Glossia 는 이를 자동으로 처리하여 PKCE 강제와 기본 인증 방법으로 회귀합니다.

### 승인 후 "Invalid OAuth callback" 오류 발생

코딩 에이전트가 `https://glossia.ai` 에 접근할 수 있는지 확인하세요. 콜백은 코딩 에이전트가 컴퓨터에서 임시로 여는 로컬 포트에서 발생합니다. Glossia 는 호스팅 상태를 유지하며, 이 로컬 리스너는 에이전트에게 속합니다. 방화벽이나 가상 사설망이 콜백을 가끔 차단할 수 있습니다.

### 토큰 교환 실패

인증 서버 메타데이터에 `code_challenge_methods_supported` 필드가 있는지 확인하세요. PKCE 가 작동하려면 서버가 S256 지원 advertisement 에서 S256 지원을 고지해야 합니다. Glossia 는 이를 기본적으로 포함합니다.

### 에이전트가 서버에 접근할 수 없습니다

설정된 엔드포인트가 `https://glossia.ai/mcp` 이며 네트워크에서 코딩 에이전트가 해당 엔드포인트에 접근할 수 있는지 확인하세요. 호스팅 서비스에 계속 접속할 수 없는 경우 Glossia 지원에 문의하세요.
