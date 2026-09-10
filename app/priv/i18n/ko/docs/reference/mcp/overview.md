%{
  title: "개요",
  summary: "모델 컨텍스트 프로토콜을 통해 Glossia 프로젝트에 코딩 에이전트를 연결하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) 서버로 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있게 합니다. 서버는 OAuth 2.1 과 PKCE 를 사용하여 동적 클라이언트 등록([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), 수동 자격 증명 설정 없이 MCP 호환 클라이언트가 인증할 수 있습니다.

## MCP 서버가 제공하는 내용

연결 후 코딩 에이전트:

- 프로젝트 전반의 번역 상태 조회
- 번역 및 수정 시작
- 설정 및 콘텐츠 항목 검토
- 프로젝트 컨텍스트를 활용한 더 스마트한 코드 제안

## 서버 URL

| 환경 | URL |
|---|---|
| 프로덕션 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 플로우

MCP 서버는 PKCE 를 적용한 표준 OAuth 2.1 인가 코드 흐름을 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요는 없습니다. 이 흐름은 다음과 같이 작동합니다:

1. 에이전트는 서버를 다음 단계를 통해 발견합니다 `/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 자신을 OAuth 클라이언트로 등록합니다
3. 로그인 및 동의를 위해 브라우저를 엽니다
4. 승인 후 에이전트는 액세스 토큰을 수신하여 모든 MCP 요청에 첨부합니다

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

Codex 설정 파일에 서버를 추가하세요 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행하세요

```bash
codex mcp login glossia
```

브라우저는 인증을 위해 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하고 향후 세션에서 사용합니다.

연결을 확인하려면

```bash
codex mcp list
```

로컬 개발을 위해 URL 을 변경하세요

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code MCP 설정에 서버를 추가하세요 (`.claude/settings.json` 또는 전역 설정 파일을):

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

### 다른 MCP 클라이언트

MCP 인증 사양을 지원하는 모든 클라이언트는 [MCP 인증 사양](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 작동합니다. 주요 요구 사항은 다음과 같습니다:

- **전송**: 스트리밍 HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호 리소스 메타데이터를 지원해야 합니다 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE (S256) 를 사용한 인증 코드

Glossia MCP 서버 URL 을 클라이언트에게 지시하여 발견 및 등록을 자동으로 처리하게 하세요.

## 검색 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하기 위해 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터 (엔드포인트, 지원되는 권한 부여 방식, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호된 리소스 메타데이터 (스코프, 인증 서버) |

## 속도 제한

OAuth 엔드포인트는 남용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 제한 |
|---|---|
| `POST /oauth/register` | 분당 5 회 요청 |
| `POST /oauth/token` | 분당 30 회 요청 |
| `POST /oauth/introspect` | 분당 30 회 요청 |
| `POST /oauth/revoke` | 분당 30 건의 요청 |

요청 수 제한을 초과하면 서버는 HTTP 429 를 `Retry-After` 헤더를 반환합니다.

## 문제 해결

### 등록이 "invalid\_client\_metadata" 오류로 실패했습니다.

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용하며, 공개 클라이언트 (대부분의 코딩 에이전트) 는 보내야 합니다. `"none"`이는 Glossia 가 PKCE 강제 항목 시 기본 인증 방식으로 자동 복귀 처리합니다.

### "잘못된 OAuth 콜백" 승인 후

설정하신 URL 에서 Glossia 서버가 실행 중이고 도달 가능한지 확인하세요. 코드 에이전트가 일시적으로 열어둔 로컬 포트에서 콜백이 발생합니다. 방화벽이나 VPN 은 때때로 이를 차단할 수 있습니다.

### 토큰 교환 실패

인증 서버 메타데이터에서 `code_challenge_methods_supported` 필드가 있는지 확인하세요. PKCE 가 작동하려면 서버가 S256 지원을 명시해야 합니다. Glossia 는 이를 기본적으로 포함합니다.

### 에이전트가 서버에 도달할 수 없음

로컬 개발 환경에서는 Phoenix 서버가 실행 중인지 (`mix phx.server`)이고, 예상 포트 (기본값: 4050) 에서 경청 중인지 확인하세요. MCP 엔드포인트는 에이전트 프로세스에서 접근 가능해야 합니다.