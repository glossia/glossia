%{
  title: "Visão geral",
  summary: "Conecte agentes de programação aos seus projetos do Glossia por meio do Model Context Protocol.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
A Glossia disponibiliza um servidor de [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) (MCP) que permite que agentes de programação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), portanto qualquer cliente compatível com MCP pode se autenticar sem a configuração manual de credenciais.

## O que o servidor MCP oferece

Após a conexão, um agente de programação pode:

- Consultar o status das traduções em seus projetos
- Acionar traduções e revisões
- Inspecionar configurações e entradas de conteúdo
- Acessar o contexto do projeto para fornecer sugestões de código mais precisas

## URL do servidor

| Ambiente | URL |
|---|---|
| Produção | `https://glossia.ai/mcp` |
| Desenvolvimento local | `http://localhost:4050/mcp` |

## Fluxo de autenticação

O servidor MCP usa o fluxo padrão de código de autorização do OAuth 2.1 com PKCE. Não é necessário criar clientes OAuth manualmente. O fluxo funciona da seguinte forma:

1. O agente descobre seu servidor por meio de `/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth pelo endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Após sua aprovação, o agente recebe um token de acesso e o inclui em todas as solicitações MCP

## Como adicionar a Glossia a um agente de programação

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

Seu navegador será aberto para autenticação. Após a aprovação, o Codex armazena o token localmente e o utiliza nas sessões futuras.

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

Adicione o servidor às configurações MCP do Claude Code (`.claude/settings.json` ou o arquivo de configurações globais):

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

O Claude Code gerenciará automaticamente o fluxo OAuth quando se conectar pela primeira vez.

### Outros clientes MCP

Qualquer cliente compatível com a [especificação de autorização do MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Os principais requisitos são:

- **Transporte**: HTTP com streaming
- **Descoberta**: o cliente deve ser compatível com os Metadados de Recurso Protegido do OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Documentos de Metadados de Identificação do Cliente
- **Fluxo de autenticação**: código de autorização com PKCE (S256)

Configure o cliente com a URL do servidor MCP da Glossia e permita que ele gerencie automaticamente a descoberta e o registro.

## Endpoints de descoberta

O servidor publica dois documentos de metadados usados pelos clientes MCP para iniciar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão compatíveis e métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados do recurso protegido (escopos e servidores de autorização) |

## Limites de requisições

Os endpoints OAuth aplicam limites de requisições para evitar abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de requisições é excedido, o servidor retorna HTTP 429 com um cabeçalho `Retry-After`.

## Solução de problemas

### O registro falha com "invalid_client_metadata"

O endpoint de registro dinâmico aceita apenas valores específicos de `token_endpoint_auth_method`. Clientes públicos (a maioria dos agentes de programação) devem enviar `"none"`, que o Glossia processa automaticamente usando como alternativa os métodos de autenticação padrão, com aplicação obrigatória de PKCE.

### "Callback OAuth inválido" após a aprovação

Verifique se o servidor Glossia está em execução e acessível na URL configurada. O callback ocorre em uma porta local que o agente de programação abre temporariamente. Firewalls ou redes privadas virtuais podem bloquear essa conexão em alguns casos.

### Falha na troca do token

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve informar compatibilidade com S256 para que PKCE funcione. O Glossia inclui essa configuração por padrão.

### O agente não consegue acessar o servidor

Para desenvolvimento local, verifique se o servidor Phoenix está em execução (`mix phx.server`) e escutando na porta esperada (padrão: 4050). O endpoint MCP deve estar acessível a partir do processo do agente.