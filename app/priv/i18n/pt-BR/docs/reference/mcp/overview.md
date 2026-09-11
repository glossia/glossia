%{
  title: "Visão geral",
  summary:
    "Conecte agentes de codificação aos seus projetos Glossia através do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---
A Glossia expõe um [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) (MCP) servidor que permite que agentes de programação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico do Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), então qualquer cliente compatível com MCP pode autenticar sem configuração manual de credenciais.

## O que o servidor MCP fornece

Depois de conectado, um agente de programação pode:

- Consultar o status de tradução em seus projetos
- Acionar traduções e revisões
- Inspecionar configurações e entradas de conteúdo
- Acessar contexto do projeto para sugestões de código mais inteligentes

## URL do Servidor

| Ambiente | URL |
|---|---|
| Produção | `https://glossia.ai/mcp` |
| Desenvolvimento local | `http://localhost:4050/mcp` |

## Fluxo de autenticação

O servidor MCP usa o fluxo padrão de código de autorização do OAuth 2.1 com PKCE. Você não precisa criar clientes OAuth manualmente. O fluxo funciona assim:

1. O agente descobre seu servidor através `/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth via o endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Depois que você aprovar, o agente recebe um token de acesso e o anexa a todas as requisições MCP

## Adicionando o Glossia a um agente de codificação

### OpenAI Codex

Adicione o servidor ao seu arquivo de configuração do Codex em `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Em seguida, execute o login do OAuth:

```bash
codex mcp login glossia
```

Seu navegador abrirá para autenticação. Depois de aprovar, o Codex armazena o token localmente e o utiliza em futuras sessões.

Para verificar a conexão:

```bash
codex mcp list
```

Para desenvolvimento local, substitua a URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Adicione o servidor às configurações MCP do Claude Code (`.claude/settings.json` ou ao arquivo de configurações globais):

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

O Claude Code gerenciará automaticamente o fluxo OAuth ao conectar-se pela primeira vez.

### Outros clientes MCP

Qualquer cliente que suporte o [especificação de autorização MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Os requisitos principais são.)

- **Transporte**: HTTP Streamável
- **Descoberta**: O cliente deve suportar os Metadados de Recursos Protegidos do OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico do Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Documentos de Metadados do Client ID
- **Fluxo de Autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para o URL do seu servidor MCP Glossia e deixe que ele realize automaticamente a descoberta e o registro.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP utilizam para inicializar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados do recurso protegido (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints do OAuth impõem limites de taxa para prevenir abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com um `Retry-After` cabeçalho.

## Solução de problemas

### O registro falha com "invalid\_client\_metadata"

O endpoint de registro dinâmico aceita apenas específicos `token_endpoint_auth_method` valores. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o qual o Glossia gerencia automaticamente ao retornar para os métodos de autenticação padrão com aplicação do PKCE.

### "OAuth callback inválido" após a aprovação

Certifique-se de que o servidor Glossia esteja em execução e acessível na URL que você configurou. O callback ocorre em uma porta local que o agente de codificação abre temporariamente. firewalls ou VPNs às vezes podem bloquear isso.

### Falha na troca de token

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve anunciar suporte S256 para que o PKCE funcione. Glossia inclui isso por padrão.

### Agente não consegue acessar o servidor

Para desenvolvimento local, certifique-se de que o servidor Phoenix esteja em execução (`mix phx.server`) e escutando na porta esperada (padrão: 4050). O endpoint MCP deve ser acessível a partir do processo do agente.