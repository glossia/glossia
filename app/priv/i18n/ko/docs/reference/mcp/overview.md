%{
  title: "개요",
  summary: "Model Context Protocol을 통해 코딩 에이전트를 Glossia 프로젝트에 연결합니다.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia는 코딩 에이전트가 현지화 프로젝트와 상호 작용할 수 있도록 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) (MCP) 서버를 제공합니다. 이 서버는 PKCE와 동적 클라이언트 등록([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))을 사용하는 OAuth 2.1을 구현하므로, 모든 MCP 호환 클라이언트가 자격 증명을 수동으로 설정하지 않고도 인증할 수 있습니다.

## MCP 서버에서 제공하는 기능

연결되면 코딩 에이전트는 다음 작업을 수행할 수 있습니다.

- 프로젝트 전반의 번역 상태 조회
- 번역 및 수정 실행
- 구성 및 콘텐츠 항목 검사
- 더 정확한 코드 제안을 위한 프로젝트 컨텍스트 액세스

## 서버 URL

| 환경 | URL |
|---|---|
| 프로덕션 | `https://glossia.ai/mcp` |
| 로컬 개발 | `http://localhost:4050/mcp` |

## 인증 흐름

MCP 서버는 PKCE를 사용하는 표준 OAuth 2.1 인증 코드 흐름을 사용합니다. OAuth 클라이언트를 수동으로 생성할 필요가 없습니다. 인증 흐름은 다음과 같습니다.

1. 에이전트가 `/.well-known/oauth-authorization-server`을 통해 서버를 탐색합니다.
2. 동적 등록 엔드포인트를 통해 자체적으로 OAuth 클라이언트로 등록합니다.
3. 로그인 및 동의를 위해 브라우저를 엽니다.
4. 승인하면 에이전트가 액세스 토큰을 받아 모든 MCP 요청에 첨부합니다.

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

`~/.codex/config.toml`의 Codex 구성 파일에 서버를 추가합니다.

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

그런 다음 OAuth 로그인을 실행합니다.

```bash
codex mcp login glossia
```

인증을 위해 브라우저가 열립니다. 승인하면 Codex가 토큰을 로컬에 저장하고 이후 세션에서 사용합니다.

연결을 확인하려면 다음을 실행합니다.

```bash
codex mcp list
```

로컬 개발 환경에서는 URL을 다음과 같이 변경합니다.

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code MCP 설정(`.claude/settings.json` 또는 전역 설정 파일)에 서버를 추가합니다.

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

Claude Code는 처음 연결할 때 OAuth 흐름을 자동으로 처리합니다.

### 기타 MCP 클라이언트

[MCP 인증 사양](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)을 지원하는 모든 클라이언트를 사용할 수 있습니다. 주요 요구 사항은 다음과 같습니다.

- **전송 방식**: 스트리밍 가능 HTTP
- **탐색**: 클라이언트가 OAuth 2.0 보호 리소스 메타데이터([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))를 지원해야 합니다.
- **등록**: 동적 클라이언트 등록([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 또는 클라이언트 ID 메타데이터 문서
- **인증 흐름**: PKCE(S256)를 사용하는 인증 코드

클라이언트가 Glossia MCP 서버 URL을 사용하도록 지정하면 탐색과 등록이 자동으로 처리됩니다.

## 탐색 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 초기화하는 데 사용하는 두 개의 메타데이터 문서를 게시합니다.

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터(엔드포인트, 지원되는 권한 부여 유형, PKCE 방식) |
| `/.well-known/oauth-protected-resource` | 보호 리소스 메타데이터(범위, 인증 서버) |

## 요청 한도

OAuth 엔드포인트는 악용을 방지하기 위해 요청 한도를 적용합니다.

| 엔드포인트 | 한도 |
|---|---|
| `POST /oauth/register` | 분당 5회 요청 |
| `POST /oauth/token` | 분당 30회 요청 |
| `POST /oauth/introspect` | 분당 30회 요청 |
| `POST /oauth/revoke` | 분당 30회 요청 |

요청 한도를 초과하면 서버는 `Retry-After` 헤더와 함께 HTTP 429를 반환합니다.

## 문제 해결

### "invalid_client_metadata" 오류로 등록 실패

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용합니다. 공개 클라이언트(대부분의 코딩 에이전트)는 `"none"`를 전송해야 합니다. Glossia는 코드 교환용 증명 키 적용과 함께 기본 인증 방식으로 대체하여 이를 자동으로 처리합니다.

### 승인 후 "잘못된 개방형 인증 콜백" 오류가 발생하는 경우

Glossia 서버가 실행 중이며 구성한 URL에서 접근 가능한지 확인하십시오. 콜백은 코딩 에이전트가 일시적으로 여는 로컬 포트에서 이루어집니다. 방화벽이나 가상 사설망이 이를 차단할 수 있습니다.

### 토큰 교환에 실패하는 경우

인증 서버 메타데이터에 `code_challenge_methods_supported` 필드가 있는지 확인하십시오. 코드 교환용 증명 키가 작동하려면 서버가 S256 지원을 명시해야 합니다. Glossia에는 이 설정이 기본으로 포함되어 있습니다.

### 에이전트가 서버에 연결할 수 없는 경우

로컬 개발 환경에서는 Phoenix 서버가 실행 중이며(`mix phx.server`) 예상 포트(기본값: 4050)에서 수신 대기 중인지 확인하십시오. 모델 컨텍스트 프로토콜 엔드포인트는 에이전트 프로세스에서 접근할 수 있어야 합니다.