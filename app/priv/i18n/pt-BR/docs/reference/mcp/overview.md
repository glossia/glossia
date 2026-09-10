%{
  title: "Visão Geral",
  summary:
    "Conecte agentes de codificação aos seus projetos Glossia através do Model Context Protocol.",
  category: "referência",
  subcategory: "mcp",
  order: 1
}
---
O Glossia expõe um [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) (MCP) servidor que permite aos agentes de codificação interagir com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ("/[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)"), portanto qualquer cliente compatível com MCP pode autenticar sem configuração manual de credenciais.

## O que o servidor MCP fornece

Uma vez conectado, um agente de codificação pode:

- Consultar o status da tradução em seus projetos
- Disparar traduções e revisões
- Inspecionar configurações e entradas de conteúdo
- Acessar contexto do projeto para sugestões de código mais inteligentes

## URL do servidor

| Ambiente | URL |
|---|---|
| Produção | `https://glossia.ai/mcp` |
| Desenvolvimento local | `http://localhost:4050/mcp` |

## Fluxo de autenticação

O servidor MCP usa o fluxo padrão de código de autorização OAuth 2.1 com PKCE. Você não precisa criar manualmente clientes OAuth. O fluxo funciona da seguinte forma:

1. O agente descobre seu servidor via `/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth via o endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Depois que você aprova, o agente recebe um token de acesso e anexa-o a todas as solicitações MCP

## Adicionando Glossia a um agente de codificação

### OpenAI Codex

Adicione o servidor ao arquivo de configuração do Codex em `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Em seguida, execute o login OAuth:

```bash
codex mcp login glossia
```

Seu navegador abrirá para autenticação. Após a aprovação, o Codex armazena o token localmente e o usa para futuras sessões.

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

Adicione o servidor às suas configurações de Claude Code MCP (`.claude/settings.json` ou ao arquivo de configurações global):

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

O Claude Code gerenciará o fluxo OAuth automaticamente ao se conectar pela primeira vez.

### Outros clientes MCP

Qualquer cliente que suporta o [especificação de autorização do MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Os principais requisitos são:

- **Transporte**: HTTP com Streaming
- **Descoberta**: O cliente deve suportar Metadados de Recurso Protegido do OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Client ID e Documentos de Metadados
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para a URL do seu servidor MCP Glossia e deixe-o lidar com a descoberta e o registro automaticamente.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP utilizam para iniciar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados de recursos protegidos (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth aplicam limites de taxa para evitar abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 requisições por minuto |
| `POST /oauth/token` | 30 requisições por minuto |
| `POST /oauth/introspect` | 30 requisições por minuto |
| `POST /oauth/revoke` | 30 requisições por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com um `Retry-After` cabeçalho.

## Solução de Problemas

### O registro falha com "invalid\_client\_metadata"

O endpoint de registro dinâmico aceita apenas específicos `token_endpoint_auth_method` valores. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o qual Glossia lida automaticamente ao retornar aos métodos de autenticação padrão com aplicação de PKCE.

### "Callback de OAuth inválido" após a aprovação

Certifique-se de que o seu servidor Glossia esteja em execução e acessível na URL que você configurou. O callback acontece em uma porta local que o agente de codificação abre temporariamente. Firewalls ou VPNs podem às vezes bloquear isso.

### Falha na troca de token

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve anunciar o suporte a S256 para que o PKCE funcione. O Glossia o inclui por padrão.

### O agente não consegue acessar o servidor

Para desenvolvimento local, certifique-se de que o servidor Phoenix esteja em execução (`mix phx.server`) e escutando na porta esperada (padrão: 4050). O endpoint MCP deve ser acessível a partir do processo do agente.