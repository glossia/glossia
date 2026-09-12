%{
  title: "개요",
  summary: "모델 컨텍스트 프로토콜을 통해 코딩 에이전트를 Glossia 프로젝트에 연결하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) 서버로 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있도록 합니다. 서버는 OAuth 2.1 과 PKCE 및 Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), so any MCP-compatible client can authenticate without manual credential setup.

## What the MCP server provides

Once connected, a coding agent can:

- Query translation status across your projects
- 번역 및 수정 작업 시작
- 구성 및 콘텐츠 항목 검토
- 프로젝트 컨텍스트 액세스를 통한 더 스마트한 코드 제안

## 서버 URL

| 환경 | URL |
|---|---|
| 운영 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 흐름

MCP 서버는 PKCE 를 적용한 표준 OAuth 2.1 인증 코드 흐름을 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요가 없습니다. 절차는 다음과 같습니다:

1. 에이전트는 서버를 발견합니다 `/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 등록합니다
3. 브라우저를 열어 로그인 및 동의를 완료합니다
4. 승인 후 에이전트는 액세스 토큰을 받아 모든 MCP 요청에 포함시킵니다

## 코드 에이전트에 Glossia 추가

### OpenAI Codex

Codex 설정 파일에 서버를 추가할 위치에서 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행하세요:

```bash
codex mcp login glossia
```

브라우저가 인증을 위해 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하고 향후 세션에서 이를 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

로컬 개발 환경에서는 URL 을 수정하세요:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code 서버를 Claude Code MCP 설정에 추가 (`.claude/settings.json` 또는 전역 설정 파일):

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code 는 처음 연결 시 자동으로 OAuth 흐름을 처리합니다.

### 기타 MCP 클라이언트

MCP 인증 규격을 지원하는 모든 클라이언트는 [MCP 인증 규격](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 작동합니다. 주요 요구사항은 다음과 같습니다:

- **전송**: 스트리밍 HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호된 리소스 메타데이터 를 지원해야 합니다 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE (S256) 인증 코드

클라이언트를 Glossia MCP 서버 URL 로 설정하여 발견 및 등록을 자동으로 처리하게 하세요.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하기 위해 사용하는 두 개의 메타데이터 문서를 제공합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인가 서버 메타데이터 (엔드포인트, 지원되는 인가 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호된 리소스 메타데이터 (스코프, 인가 서버) |

## 속도 제한

OAuth 엔드포인트는 남용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 제한 |
|---|---|
| `POST /oauth/register` | 1 분당 5 요청 |
| `POST /oauth/token` | 1 분당 30 요청 |
| `POST /oauth/introspect` | 1 분당 30 요청 |
| `POST /oauth/revoke` | 분당 30 회 요청 |

속도 제한을 초과하면 서버는 HTTP 429 와 함께 `Retry-After` 헤더를 반환합니다.

## 문제 해결

### 등록이 "invalid\_client\_metadata" 오류로 실패합니다

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용합니다. 공개 클라이언트 (대부분의 코딩 에이전트) 는 보내야 합니다 `"none"`, Glossia 는 PKCE 강제 적용하에 기본 인증 방식으로 자동으로 처리합니다.

### 승인 후 "올바르지 않은 OAuth 콜백"

설정하신 URL 에서 Glossia 서버가 실행되고 접근 가능한지 확인하세요. 콜백은 코딩 에이전트가 일시적으로 여는 로컬 포트에서 발생하며, 방화벽이나 VPN 은 가끔 이를 차단할 수 있습니다.

### 토큰 교환 실패

인증 서버 메타데이터에 `code_challenge_methods_supported` 필드가 있는지 확인하세요. PKCE 가 작동하려면 서버는 S256 지원을 표시해야 합니다. Glossia 는 기본적으로 이를 포함합니다.

### 에이전트가 서버에 도달할 수 없음

로컬 개발의 경우, Phoenix 서버가 (`mix phx.server`) 실행 중이며 기대하는 포트 (기본값: 4050) 에서 경청하고 있는지 확인하세요. MCP 엔드포인트는 에이전트 프로세스에서 접근 가능해야 합니다.