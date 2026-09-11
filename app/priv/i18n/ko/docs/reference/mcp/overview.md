%{
  title: "개요",
  summary: "Model Context Protocol 를 통해 내 Glossia 프로젝트에 코드 에이전트를 연결하세요.",
  category: "참고",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 ... 을 제공합니다 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) 서버는 로컬라이제이션 프로젝트와 코딩 에이전트의 상호작용을 가능하게 합니다. 서버는 OAuth 2.1 와 PKCE 및 Dynamic Client Registration([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 수동 자격 증명 설정 없이 MCP 호환 클라이언트가 인증할 수 있습니다.

## MCP 서버가 제공하는 기능

연결 후 코딩 에이전트는 할 수 있습니다.

- 프로젝트 전체의 번역 상태 조회
- 번역 및 수정 시작하기
- 구성 및 콘텐츠 항목 검토하기
- 프로젝트 컨텍스트 접근을 통한 더 스마트한 코드 제안

## 서버 URL

| 환경 | URL |
|---|---|
| 프로덕션 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 흐름

MCP 서버는 PKCE 와 함께 표준 OAuth 2.1 인증 코드 흐름을 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요가 없습니다. 이 흐름은 다음과 같습니다:

1. 에이전트는 이를 통해 서버를 발견합니다 `/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 등록합니다
3. 로그인 및 동의를 위해 브라우저 창을 엽니다
4. 승인 후 에이전트는 액세스 토큰을 받아 모든 MCP 요청에 첨부합니다

## 코드 에이전트에 Glossia 추가

### OpenAI Codex

Codex 설정 파일에 서버를 추가하세요 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행하세요:

```bash
codex mcp login glossia
```

인증 목적으로 브라우저가 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하고 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

로컬 개발을 위해 URL 을 변경하세요:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code MCP 설정에 서버를 추가하세요 (`.claude/settings.json` 또는 전역 설정 파일):

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

Claude Code 는 처음 연결 시 OAuth 플로우를 자동으로 처리합니다.

### 기타 MCP 클라이언트

MCP 인증 사양을 지원하는 모든 클라이언트가 [MCP 인증 사양](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 작동합니다. 주요 요구 사항은 다음과 같습니다:

- **수송**: 스트리밍 가능한 HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호 리소스 메타데이터 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE (S256) 를 사용한 인증 코드

Glossia MCP 서버 URL 로 클라이언트를 지시하고 발견 및 등록을 자동으로 처리하도록 하세요.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하기 위해 사용하는 두 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터 (엔드포인트, 지원되는 위임 유형, PKCE 방식) |
| `/.well-known/oauth-protected-resource` | 보호된 리소스 메타데이터 (스코프, 인증 서버) |

## 속도 제한

OAuth 엔드포인트는 남용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 한도 |
|---|---|
| `POST /oauth/register` | 분당 5 회 요청 |
| `POST /oauth/token` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |
| `POST /oauth/revoke` | 분당 30 요청 |

요청 제한 초과 시, 서버는 HTTP 429 와 함께 `Retry-After` 헤더를 반환합니다.

## 문제 해결

### 등록이 "invalid\_client\_metadata" 오류로 실패했습니다

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값을 전송해야 합니다. 공개 클라이언트 (대부분의 코딩 에이전트) `"none"`, Glossia 는 자동으로 기본 인증 방법 대신 PKCE 강제를 처리합니다.

### 승인 후 "잘못된 OAuth 콜백"

설정한 URL 에서 Glossia 서버가 실행 중이며 접근 가능하도록 확인하세요. 콜백은 코딩 에이전트가 일시적으로 여는 로컬 포트에서 발생합니다. 방화벽 또는 VPN 은 때때로 이를 차단할 수 있습니다.

### 토크인 교환 실패

 다음 확인`code_challenge_methods_supported`필드가 인증 서버 메타데이터에 존재하며 PKCE 가 작동하려면 서버는 S256 을 지원해야 합니다. Glossia 는 기본적으로 이 기능을 포함합니다

### 에이전트가 서버에 도달할 수 없습니다

 로컬 개발 환경에서는 Phoenix 서버가 실행 중인지`mix phx.server` agré 카테고리 expects 도되는 포트 (기본값: 4050) 에서 수신 대기 중이어야 하며, 에이전트 프로세스에서 MCP 엔드포인트가 도달 가능해야 합니다