%{
  title: "Visão geral",
  summary:
    "Conecte os agentes de programação aos seus projetos Glossia através do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---
Glossia expõe um [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servidor que permite que agentes de codificação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), então qualquer cliente compatível com MCP pode autenticar sem configuração manual de credenciais.

## O que o servidor MCP oferece

Uma vez conectado, um agente de codificação pode:

- Consultar o status de tradução em seus projetos
- Iniciar traduções e revisões
- Inspecionar configurações e entradas de conteúdo
- Acessar contexto do projeto para sugestões de código mais inteligentes

## URL do Servidor

| Ambiente | URL |
|---|---|
| Produção | `https://glossia.ai/mcp` |
| Desenvolvimento local | `http://localhost:4050/mcp` |

## Fluxo de autenticação

O servidor MCP usa o fluxo de código de autorização OAuth 2.1 padrão com PKCE. Você não precisa criar clientes OAuth manualmente. O fluxo funciona da seguinte forma:

1. O agente descobre seu servidor através `/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth via o endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Após sua aprovação, o agente recebe um token de acesso e o anexa a todas as solicitações MCP

## Adicionando o Glossia a um agente de código

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

Seu navegador abrirá para autenticação. Após aprovar, o Codex armazena o token localmente e o usa para futuras sessões.

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

Adicione o servidor às suas configurações do Claude Code MCP (`.claude/settings.json` ou no arquivo de configurações global):

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

O Claude Code gerenciará automaticamente o fluxo OAuth na primeira conexão.

### Outros clientes MCP

Qualquer cliente que suporte a [Especificação de autorização do MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Os requisitos principais são:

- **Transporte**: HTTP Streamável
- **Descoberta**: O cliente deve suportar Metadados de Recurso Protegido OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Documentos de Metadados de ID do Cliente
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para a URL do seu servidor MCP do Glossia e deixe-o lidar com a descoberta e o registro automaticamente.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP utilizam para iniciar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados de recursos protegidos (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth impõem limites de taxa para prevenir abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 requisições por minuto |
| `POST /oauth/token` | 30 requisições por minuto |
| `POST /oauth/introspect` | 30 requisições por minuto |
| `POST /oauth/revoke` | 30 requisições por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com uma `Retry-After` cabeçalho.

## Solução de problemas

### O registro falha com "invalid\_client\_metadata"

O endpoint de registro dinâmico aceita apenas específicos `token_endpoint_auth_method` valores. Os clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o qual o Glossia gerencia automaticamente ao recuar para métodos de autenticação padrão com obrigatoriedade de PKCE.

### "Retorno OAuth inválido" após a aprovação

Certifique-se de que o servidor Glossia esteja em execução e acessível na URL que você configurou. A chamada de retorno ocorre em uma porta local que o agente de codificação abre temporariamente. Firewalls ou VPNs podem às vezes bloquear isso.

### A troca de tokens falha

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve anunciar suporte ao S256 para que o PKCE funcione. O Glossia inclui isso por padrão.

### O agente não consegue acessar o servidor

Para desenvolvimento local, certifique-se de que o servidor Phoenix esteja em execução (`mix phx.server`) e escutando na porta esperada (padrão: 4050). O endpoint MCP deve ser acessível pelo processo do agente.