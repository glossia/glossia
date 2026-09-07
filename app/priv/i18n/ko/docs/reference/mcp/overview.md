%{
  title: "개요",
  summary: "Model Context Protocol 을 통해 Glossia 프로젝트에 코딩 에이전트를 연결하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 제공해 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) (MCP) 서버는 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있도록 합니다. 이 서버는 OAuth 2.1 과 PKCE 및 Dynamic Client Registration ([RFC 7591\]](https://datatracker.ietf.org/doc/html/rfc7591)) , 따라서 MCP 호환 클라이언트는 수동 인증 설정 없이 인증할 수 있습니다.

## MCP 서버가 제공하는 내용

연결되면 코딩 에이전트는:

- 프로젝트 전체의 번역 상태를 조회합니다
- 번역 및 수정 시작
- 구성 및 콘텐츠 항목 검토
- 프로젝트 컨텍스트 액세스를 통한 더 똑똑한 코드 제안

## 서버 URL

| 환경 | URL |
|---|---|
| 프로덕션 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 흐름

MCP 서버는 PKCE 와 함께 표준 OAuth 2.1 인증 코드 흐름을 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요는 없습니다. 흐름은 다음과 같이 작동합니다.

1. 에이전트는 서버를 이를 통해 발견합니다 `/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 등록됩니다
3. 로그인 및 동의를 위해 브라우저를 엽니다
4. 승인 후 에이전트는 액세스 토큰을 받아 모든 MCP 요청에 첨부합니다

## 코드 에이전트에 Glossia 추가

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

브라우저가 인증을 위해 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하고 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

로컬 개발을 위해 URL 을 교체하세요:

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

MCP 인증 사양을 지원하는 모든 클라이언트는 [MCP 인증 사양](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 작동합니다. 주요 요구사항은:

- **전송**: 스트림 가능한 HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호된 리소스 메타데이터 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE (S256) 를 사용한 인증 코드

클라이언트를 Glossia MCP 서버 URL 로 설정하고, 발견 및 등록을 자동으로 처리하게 하세요.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 초기화하는 데 사용하는 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 권한 부여 서버 메타데이터 (엔드포인트, 지원된 그랜트 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호 리소스 메타데이터 (스코프, 권한 부여 서버) |

## 속도 제한

OAuth 엔드포인트는 악용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 한도 |
|---|---|
| `POST /oauth/register` | 분당 5 요청 |
| `POST /oauth/token` | 분당 30 요청 |
| `POST /oauth/introspect` | 분당 30 요청 |
| `POST /oauth/revoke` | 분당 30 개의 요청 |

속도 제한 을 초과하면 서버 는 HTTP 429 를 반환하며 `Retry-After` 헤더.

## 문제 해결

### 등록이 "invalid\_client\_metadata" 오류로 실패합니다.

동적 등록 엔드포인트 는 특정 값 만 허용합니다. `token_endpoint_auth_method` 값 을 전송해야 합니다. 공개 클라이언트 (대부분의 코딩 에이전트) 는 `"none"`, Glossia 는 자동으로 기본 인증 방법으로 전환하여 PKCE 를 강제합니다.

### 승인 후 \\"잘못된 OAuth 콜백\\"

설정하신 URL 에서 Glossia 서버가 실행되고 도달 가능한지 확인하세요. 콜백은 코딩 에이전트가 임시로 열게 되는 로컬 포트에서 발생합니다. 방화벽 또는 VPN 은 때때로 이를 차단할 수 있습니다.

### 토큰 교환 실패

다음 이 있는지 확인하세요`code_challenge_methods_supported` 인증 서버 메타데이터에 해당 필드가 포함되어 있는지 확인하세요. PKCE 가 작동하려면 서버는 S256 지원을 광고해야 합니다. Glossia 는 기본적으로 이를 포함합니다.

### 에이전트가 서버에 도달할 수 없습니다

로컬 개발 환경에서는 Phoenix 서버가 실행 중인지 확인해야 합니다 (`mix phx.server`) 예상 포트 (기본값: 4050) 에서 수신 중이어야 합니다. 에이전트 프로세스에서 MCP 엔드포인트가 접근 가능해야 합니다.