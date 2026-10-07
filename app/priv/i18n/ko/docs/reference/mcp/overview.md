%{
  title: "개요",
  summary: "Model Context Protocol 을 통해 코딩 에이전트를 귀하의 Glossia 프로젝트에 연결합니다.",
  category: "참조",
  subcategory: "mcp",
  order: 1
}
---
Glossia 는 다음을 제공합니다. [Model Context Protocol](https://modelcontextprotocol.io) (MCP) 서버는 코딩 에이전트가 현지화 프로젝트와 상호작용할 수 있도록 합니다. 서버는 PKCE 와 Dynamic Client 등록을 포함한 OAuth 2.1 를 구현합니다. ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))

## MCP 서버가 제공하는 기능

연결 후 코딩 에이전트는 권한에 따라 계정 및 프로젝트 목록 조회, 프로젝트 생성, 조직 구성원 및 초대 관리, 음성 및 용어집 설정 읽기 또는 수정, 계정 모델 및 토큰 관리 등을 수행할 수 있습니다.

현재 서버는 번역 시작 또는 수정 작업을 시작하거나, 파일별 번역 상태를 검사하기 위한 도구를 제공하지 않습니다. 자세한 내용은 확인하시기 바랍니다. [도구 참조](/docs/reference/mcp) 사용 가능한 도구에 대한 것입니다.

## 서버 URL

아래 Glossia 의 호스팅 서비스에 연결하세요. `https://glossia.ai/mcp`. Glossia 는 이 엔드포인트를 운영 및 유지 관리하며, 연결 구성은 코드 에이전트에서만 수행됩니다.

## 인증 프로세스

MCP 서버는 표준 OAuth 2.1 인증 코드 흐름 및 PKCE 를 사용합니다. 수동으로 OAuth 클라이언트를 생성할 필요가 없습니다. 흐름은 다음과 같이 작동합니다:

1. 에이전트는 다음을 통해 Glossia 를 발견합니다. `https://glossia.ai/.well-known/oauth-authorization-server`
2. 동적 등록 엔드포인트를 통해 OAuth 클라이언트로 등록됩니다.
3. 로그인 및 동의를 위해 브라우저가 열립니다.
4. 승인 후 에이전트는 액세스 토큰을 수신하여 모든 MCP 요청에 첨부합니다.

## 코딩 에이전트에 Glossia 추가

### OpenAI Codex

아래 [Codex 연결 가이드](https://developers.openai.com/codex/mcp), Codex 설정 파일에 서버를 추가하세요 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

이어서 OAuth 로그인을 실행하십시오:

```bash
codex mcp login glossia
```

인증 시 브라우저가 열립니다. 승인 후, Codex 는 토큰을 로컬에 저장하여 향후 세션에 사용합니다.

연결을 확인하려면:

```bash
codex mcp list
```

### Claude Code

문서에 기술된 명령을 사용하여 호스팅 서버를 추가 [Claude Code 연결 가이드](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

실행 `/mcp` Claude Code 에서 실행하고 브라우저 인증 흐름을 따르세요.

### 기타 MCP 클라이언트

클라이언트는 다음을 [Model Context Protocol 인증 흐름](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) Glossia 에서 구현됩니다. 연결에는 다음이 필요합니다:

- **수송**: Streamable HTTP
- **발견**: 클라이언트는 OAuth 2.0 보호된 리소스 메타데이터 를 지원해야 합니다 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **등록**: 동적 클라이언트 등록 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **인증 흐름**: PKCE (S256) 기반 인가 코드

클라이언트를 `https://glossia.ai/mcp` 그리고 발견 및 등록을 자동으로 처리하게 하세요.

## 발견 엔드포인트

서버는 MCP 클라이언트가 OAuth 흐름을 시작하기 위해 사용하는 두 개의 메타데이터 문서를 게시합니다:

| 엔드포인트 | 설명 |
|---|---|
| `/.well-known/oauth-authorization-server` | 인증 서버 메타데이터 (엔드포인트, 지원되는 인가 유형, PKCE 방법) |
| `/.well-known/oauth-protected-resource` | 보호된 리소스 메타데이터 (권한, 인증 서버) |

## 속도 제한

OAuth 엔드포인트는 남용을 방지하기 위해 속도 제한을 적용합니다:

| 엔드포인트 | 속도 한도 |
|---|---|
| `POST /oauth/register` | 분당 5 요청 |
| `POST /oauth/token` | 분당 30 요청 |
| `POST /oauth/introspect` | 분당 30 요청 |
| `POST /oauth/revoke` | 분당 30 요청 |

속도 제한을 초과하는 경우 서버는 HTTP 429 와 함께 `Retry-After` 헤더를 반환합니다.

## 문제 해결

### 등록이 "invalid\_client\_metadata" 오류로 인해 실패했습니다.

동적 등록 엔드포인트는 구체적인 `token_endpoint_auth_method` 값입니다. 공개 클라이언트 (대부분의 코딩 에이전트) 는 전송해야 합니다 `"none"`, Glossia 는 자동으로 기본 인증 방식으로 되돌리며 PKCE 강제 방식으로 처리합니다.

### "승인 후 OAuth 콜백 오류"

코딩 에이전트가 연결할 수 있는지 확인하세요 `https://glossia.ai`. 코딩 에이전트가 컴퓨터에서 임시로 여는 로컬 포트에서 콜백이 발생합니다. Glossia 는 호스팅된 상태로 유지되며, 이 로컬 리스너는 에이전트에 속합니다. 방화벽이나 가상 사설망은 때때로 콜백을 차단할 수 있습니다.

### 토큰 교환 실패

확인하세요 `code_challenge_methods_supported` 해당 필드는 인증 서버 메타데이터에 포함되어 있어야 합니다. PKCE 가 작동하려면 서버는 S256 지원을 명시해야 합니다. Glossia 는 이를 기본으로 포함합니다.

### 에이전트가 서버에 접근할 수 없습니다

설정된 엔드포인트가 `https://glossia.ai/mcp` 그리고 네트워크가 코딩 에이전트가 해당 서버에 접근할 수 있도록 허용하는지 확인하세요. 호스팅 서비스가 계속 사용 불가하다면 Glossia 지원에 문의하세요.