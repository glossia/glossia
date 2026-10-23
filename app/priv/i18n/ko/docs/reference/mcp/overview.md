%{
  title: "개요",
  summary: "Model Context Protocol 을 통해 Glossia 프로젝트에 코딩 에이전트를 연동하세요.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---

Glossia 에서 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) (MCP) 서버를 제공하여 코딩 에이전트가 로컬라이제이션 프로젝트와 상호작용할 수 있게 합니다. 서버는 PKCE 와 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 을 구현한 OAuth 2.1 을 사용하므로, 모든 MCP 호환 클라이언트가 수동 인증정보 설정 없이 인증할 수 있습니다.

## MCP 서버가 제공하는 기능

연결되면 코딩 에이전트는 계정과 프로젝트를 나열하고, 프로젝트를 생성하며, 조직 구성원 및 초대 메시지를 관리하고, 음성 및 사전 설정을 읽거나 업데이트하며, 계정 모델 및 토큰을 관리할 수 있습니다. (해당 권한의 범위 내에서)

현재 서버는 번역 또는 수정을 시작하거나 파일별 번역 상태를 확인하는 도구를 노출하지 않습니다. 사용 가능한 도구는 [tool reference](/docs/reference/mcp) 를 참조하십시오.

## 서버 URL

`https://glossia.ai/mcp` 주소의 Glossia 호스팅 서비스에 연결하십시오. 이 엔드포인트는 Glossia 가 운영 및 유지 관리하며, 연결 설정은 코딩 에이전트에서만 수행됩니다.

## 인증 흐름

MCP 서버는 PKCE 를 사용하는 표준 OAuth 2.1 인증 코드 흐름을 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요는 없습니다. 흐름은 다음과 같습니다:

1. 에이전트는 `https://glossia.ai/.well-known/oauth-authorization-server` 를 통해 Glossia 를 발견합니다.
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 스스로를 등록합니다.
3. 브라우저로 로그인 및 동의를 위해 열립니다.
4. 승인이 완료되면 에이전트는 액세스 토큰을 받게 되며 이를 모든 MCP 요청에 첨부합니다.

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

[Codex 연결 가이드](https://developers.openai.com/codex/mcp)를 참고하여 Codex 설정 파일 (`~/.codex/config.toml` 위치) 에 서버를 추가합니다:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

이후 OAuth 로그인을 실행합니다:

```bash
codex mcp login glossia
```

브라우저가 인증을 위해 열립니다. 승인 후 Codex 는 토큰을 로컬에 저장하고 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

### Claude Code

[Claude Code 연결 가이드](https://code.claude.com/docs/en/mcp)에 문서화된 명령어로 호스팅 서버를 추가합니다:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Claude Code 내부에서 `/mcp` 를 실행하고 브라우저 인증 흐름에 따라 진행합니다.

### 기타 MCP 클라이언트

클라이언트는 Glossia 가 구현한 [모델 컨텍스트 프로토콜 인증 흐름](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 을 지원해야 합니다. 연결에는 다음이 필요합니다:

- **수송**: 스트리밍 가능 HTTP
- **탐색**: 클라이언트는 OAuth 2.0 보호 리소스 메타데이터 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)) 을 지원해야 합니다.
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **인증 흐름**: PKCE(S256) 인증 코드

클라이언트를 `https://glossia.ai/mcp` 로 설정하고 탐색 및 등록을 자동으로 처리하게 합니다.

## 탐지 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하는 데 사용하는 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터 (엔드포인트, 지원된 토큰 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호 리소스 메타데이터 (범위, 인증 서버) |

## 속도 제한

OAuth 엔드포인트는 남용을 방지하기 위해 속도 제한을 강제합니다:

| 엔드포인트 | 제한 |
|---|---|
| `POST /oauth/register` | 분 당 5 회 요청 |
| `POST /oauth/token` | 분 당 30 회 요청 |
| `POST /oauth/introspect` | 분 당 30 회 요청 |
| `POST /oauth/revoke` | 분 당 30 회 요청 |

속도 제한을 초과하면 서버는 `Retry-After` 헤더와 함께 HTTP 429 을 반환합니다.

## 문제 해결

### 등록이 "invalid_client_metadata" 로 실패합니다.

동적 등록 엔드포인트는 특정 `token_endpoint_auth_method` 값만 허용합니다. 공개 클라이언트 (대부분의 코딩 에이전트) 는 `"none"`를 전송해야 하며, Glossia 는 PKCE 강제 하에 기본 인증 방식으로 자동으로 처리합니다.

### 승인 후 "Invalid OAuth callback"

코딩 에이전트가 `https://glossia.ai`에 접근할 수 있는지 확인하세요. 호출백은 코딩 에이전트가 컴퓨터에서 임시로 열거하는 로컬 포트에서 발생합니다. Glossia 는 계속 호스팅되며, 이 로컬 리스너는 에이전트에 속합니다. 방화벽이나 가상 사설망은 가끔 호출백을 차단할 수 있습니다.

### 토큰 교환 실패

인증 서버 메타데이터에 `code_challenge_methods_supported` 필드가 포함되어 있는지 확인하세요. 서버는 PKCE 가 작동하려면 S256 지원을 표시해야 합니다. Glossia 는 기본적으로 이를 포함합니다.

### 에이전트가 서버에 도달할 수 없습니다

구성된 엔드포인트가 `https://glossia.ai/mcp`인지 확인하고, 네트워크가 코딩 에이전트가 이를 도달할 수 있도록 허용됩니다. 호스팅 서비스가 계속 사용 불가능한 경우 Glossia 지원팀과 연락하세요.
