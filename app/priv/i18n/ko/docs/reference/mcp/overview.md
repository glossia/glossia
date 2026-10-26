%{
  title: "개요",
  summary: "모델 컨텍스트 프로토콜을 통해 코딩 에이전트를 Glossia 프로젝트에 연결하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---

Glossia 는 [Model Context Protocol](https://modelcontextprotocol.io)(MCP) 서버를 노출하여 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있게 합니다. 서버는 OAuth 2.1 과 PKCE 및 Dynamic Client Registration([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))을 구현하므로, 모든 MCP 호환 클라이언트가 수동 credential 설정 없이 인증할 수 있습니다.

## MCP 서버가 제공하는 것

연결되면 코딩 에이전트는 계정과 프로젝트를 열거하고, 프로젝트를 생성하며, 조직 구성원과 초대문을 관리하고, voice 및 glossary 설정을 읽거나 업데이트하며, 권한에 따라 계정 모델과 토큰을 관리할 수 있습니다.

서버는 현재 번역이나 리뷰를 시작하거나, 파일별 번역 상태를 점검하기 위한 도구를 노출하지 않습니다. 사용 가능한 도구는 [tool reference](/docs/reference/mcp)를 참조하세요.

## 서버 URL

Glossia 의 호스팅 서비스 `https://glossia.ai/mcp`. 에 연결하세요. Glossia 가 이 엔드포인트를 실행하고 관리하며; 연결은 코딩 에이전트에서만 구성할 수 있습니다.

## 인증 프로세스

MCP 서버는 PKCE 를 적용한 표준 OAuth 2.1 인증 코드 플로우를 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요가 없습니다. 플로우의 과정은 다음과 같습니다:

1. 에이전트는 `https://glossia.ai/.well-known/oauth-authorization-server` 를 통해 Glossia 를 발견합니다.
2. 동적 등록 엔드포인트를 통해 자체를 OAuth 클라이언트로 등록합니다.
3. 브라우저를 로그인 및 동의창을 위해 엽니다.
4. 승인 후 에이전트는 액세스 토큰을 수신하며 모든 MCP 요청에 첨부합니다.

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

[Codex 연결 가이드](https://developers.openai.com/codex/mcp)에 따라 코딩 에이전트의 설정 파일 `~/.codex/config.toml` 에 서버를 추가합니다:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

이어 OAuth 로그인を実行합니다:

```bash
codex mcp login glossia
```

브라우저가 인증을 위해 열립니다. 승인이 완료되면 Codex 는 토큰을 로컬에 저장하고 향후 세션에서 사용합니다.

연결을 확인합니다:

```bash
codex mcp list
```

### Claude Code

호스팅 서버를 [Claude Code 의 연결 가이드](https://code.claude.com/docs/en/mcp)에 문서화된 명령어로 추가합니다:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Claude Code 에서 `/mcp` 를 실행하고 브라우저 인증 프로세스를 따릅니다.

### 기타 MCP 클라이언트

클라이언트는 Glossia 가 구현한 [Model Context Protocol 인증 프로세스](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 를 지원해야 합니다. 연결에는 다음과 같은 요구 사항이 있습니다:

- **Transport**: Streamable HTTP
- **Discovery**: 클라이언트는 OAuth 2.0 Protected Resource Metadata([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))를 지원해야 합니다.
- **Registration**: Dynamic Client Registration([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth flow**: PKCE(S256) 를 사용한 인증 코드

클라이언트를 `https://glossia.ai/mcp` 에 지시하고 발견 및 등록을 자동으로 처리하게 합니다.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 프로세스를 부팅할 수 있도록 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | Authorization 서버 메타데이터(엔드포인트, 지원 가능한 grant 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | Protected 리소스 메타데이터(scope, authorization服务器) |

## Rate limits

OAuth 엔드포인트는 남용을 방지하기 위해 rate limits 를 강제합니다:

| 엔드포인트 | 제한 |
|---|---|
| `POST /oauth/register` | 5 요청/분 |
| `POST /oauth/token` | 30 요청/분 |
| `POST /oauth/introspect` | 30 요청/분 |
| `POST /oauth/revoke` | 30 요청/분 |

rate limit 이 초과되면 서버는 `Retry-After` 헤더와 함께 HTTP 429 을 반환합니다.

## 문제 해결

### 등록이 "invalid_client_metadata" 오류로 실패하는 경우

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용합니다. 공개 클라이언트 (대부분의 코딩 에이전트) 는 `"none"` 를 전송해야 하며, Glossia 는 PKCE 강제를 적용한 기본 인증 방법으로 자동으로 처리합니다.

### 승인 후 "Invalid OAuth callback"

코딩 에이전이 `https://glossia.ai` 에 도달할 수 있는지 확인하세요. 콜백은 코딩 에이전이 컴퓨터에서 일시적으로 열 수 있는 로컬 포트를 통해 발생합니다. Glossia 는 호스팅되어 있으며 이 로컬 리스너는 에이전트에 속합니다. 방화벽이나 VPN 은 때때로 콜백을 차단할 수 있습니다.

### 토큰 교환 실패

인증 서버 메타데이터에 `code_challenge_methods_supported` 필드가 있는지 확인하세요. PKCE 가 작동하려면 서버는 S256 지원 여부를 표시해야 합니다. Glossia 는 기본적으로 이 기능을 포함합니다.

### 에이전트가 서버에 도달할 수 없습니다

설정된 엔드포인트가 `https://glossia.ai/mcp` 인지 확인하고 네트워크가코딩 에이전트가 이를 도달할 수 있게 허용하는지 확인하세요. 호스팅된 서비스가 여전히 사용 불가능하면 Glossia 지원에 문의하세요.
