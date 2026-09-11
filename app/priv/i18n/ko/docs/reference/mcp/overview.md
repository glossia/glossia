%{
  title: "개요",
  summary: "모델 컨텍스트 프로토콜을 통해 코딩 에이전트를 Glossia 프로젝트에 연결하세요.",
  category: "참고",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) (MCP) 서버는 코드 에이전트가 귀하의 현지화 프로젝트와 상호작용할 수 있도록 돕습니다. 이 서버는 OAuth 2.1 과 PKCE 및 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), 따라서 모든 MCP 호환 클라이언트는 수동 자격 증명 설정 없이 인증할 수 있습니다.

## MCP 서버가 제공하는 기능

연결 후 코딩 에이전트는 다음을 수행할 수 있습니다:

- 프로젝트 전반의 번역 상태를 확인합니다
- 번역 및 수정 시작
- 구성 및 콘텐츠 항목 검토
- 더 똑똑한 코드 제안을 위한 프로젝트 컨텍스트 액세스

## 서버 URL

| 환경 | URL |
|---|---|
| 프로덕션 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 흐름

MCP 서버는 표준 OAuth 2.1 인증 코드 흐름 (PKCE) 을 사용합니다. OAuth 클라이언트를 수동으로 생성할 필요가 없습니다. 흐름은 다음과 같습니다:

1. 에이전트는 서버를 발견합니다. `/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 자신을 등록합니다
3. 로그인 및 동의를 위해 브라우저를 엽니다
4. 승인 후 에이전트는 액세스 토큰을 받고 모든 MCP 요청에 첨부합니다

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

서버를 Codex 설정 파일에 추가하세요 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행하세요:

```bash
codex mcp login glossia
```

브라우저는 인증을 위해 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하여 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

로컬 개발 시 URL 을 교체하세요:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code MCP 설정 (서버를 추가하세요,`.claude/settings.json` 또는 전역 설정 파일 ):

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

Claude Code 는 첫 연결 시 자동으로 OAuth 플로우 를 처리합니다.

### 기타 MCP 클라이언트

지원하는 모든 클라이언트가 [MCP 권한 부여 규격](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 작동할 수 있습니다. 주요 요구 사항은 다음과 같습니다:

- **전송**: 스트림 가능한 HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호 리소스 메타데이터 를 지원해야 합니다 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE (S256) 를 사용한 인가 코드

클라이언트를 귀사의 Glossia MCP 서버 URL 로 지정하고 발견 및 등록을 자동으로 처리하게 하십시오.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하기 위해 사용하는 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인가 서버 메타데이터 (엔드포인트, 지원된 인가 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호된 리소스 메타데이터 (스코프, 인가 서버) |

## 속도 제한

OAuth 엔드포인트는 오용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 한도 |
|---|---|
| `POST /oauth/register` | 5 분당 요청 |
| `POST /oauth/token` | 30 분당 요청 |
| `POST /oauth/introspect` | 30 분당 요청 |
| `POST /oauth/revoke` | 분당 30 요청 |

속도 제한을 초과하면 서버는 HTTP 429 와 함께 `Retry-After` 헤더로 반환합니다.

## 문제 해결

### 등록이 "invalid\_client\_metadata"로 실패합니다

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값을 받습니다. 공개 클라이언트 (대부분의 코드 에이전트) 는 전송해야 `"none"`, Glossia 는 PKCE 강제 적용을 포함한 기본 인증 방식으로 자동 처리합니다.

### 승인 후 "유효하지 않은 OAuth 콜백"

Glossia 서버가 설정한 URL 에서 실행 중이며 접근 가능하도록 확인하세요. 콜백은 코딩 에이전트가 임시로 여는 로컬 포트에서 발생합니다. 방화벽이나 VPN 이 때때로 이를 막을 수 있습니다.

### 토큰 교환 실패

확인하세요`code_challenge_methods_supported`인증 서버 메타데이터에 필드가 존재한인지 확인하려면@ 필드가 있어야 합니다. 서버는 PKCE 가 작동하도록 S256 보증을 광고해야 합니다. Glossia 는 기본적으로 이 기능을 포함합니다.

### 에지έν이 서버에 도달할 수 없다

로컬 개발을 위해 Phoenix 서버 를 실행 (`mix phx.server`) 중임을 확인 (