%{
  title: "Visão Geral",
  summary:
    "Conecte agentes de codificação aos seus projetos do Glossia através do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---
Glossia expõe um servidor [Protocolo de Contexto do Modelo (MCP)](https://modelcontextprotocol.io) que permite que agentes de codificação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), de modo que qualquer cliente compatível com MCP possa autenticar-se sem configuração manual de credenciais.

## O que o servidor MCP fornece

Conectado, um agente de codificação pode:

- Consultar o status de tradução em todos os projetos
- Acionar traduções e revisões
- Examinar entradas de configuração e conteúdo
- Acessar contexto do projeto para sugestões de código mais inteligentes

## URL do Servidor

| Ambiente | URL |
|---|---|
| Produção | `https://glossia.ai/mcp` |
| Desenvolvimento local | `http://localhost:4050/mcp` |

## Fluxo de autenticação

O servidor MCP utiliza o fluxo padrão de autorização OAuth 2.1 com PKCE. Não é necessária a criação manual de clientes OAuth. O fluxo funciona da seguinte forma:

1. O agente detecta seu servidor por meio de `/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth via o endpoint de registro dinâmico
3. Abre seu navegador para login e consentimento
4. Após sua aprovação, o agente recebe um token de acesso e o anexa a todas as solicitações MCP

## Adicionar Glossia a um agente de codificação

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

Seu navegador será aberto para autenticação. Após a aprovação, o Codex armazena o token localmente e o utiliza para futuras sessões.

Para verificar a conexão:

```bash
codex mcp list
```

Para desenvolvimento local, substitua o URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Adicione o servidor às configurações do Claude Code MCP (`.claude/settings.json` ou o arquivo global de configurações):

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

O Claude Code gerencia automaticamente o fluxo OAuth na primeira conexão.

### Outros clientes MCP

Qualquer cliente que suporte a [Especificação de Autenticação MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Os requisitos principais são:

- **Transporte**: HTTP Streamável
- **Descoberta**: O cliente deve suportar Metadados de Recursos Protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Documentos de Metadados de ID de Cliente
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para o URL do servidor MCP Glossia e deixe-o lidar com descoberta e registro automaticamente.

## Pontos de descoberta

O servidor publica dois documentos de metadados que os clientes MCP usam para iniciar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados de recurso protegido (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth impõem limites de taxa para evitar abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com o cabeçalho `Retry-After`.

## Solução de problemas

### Registro falha com "invalid\_client\_metadata"

O endpoint de registro dinâmico aceita apenas valores específicos para `token_endpoint_auth_method`. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o qual o Glossia lida automaticamente, alternando para métodos padrão de autenticação com PKCE obrigatório.

### "Chamada OAuth inválida" após aprovação

Certifique-se de que o servidor Glossia esteja em execução e acessível na URL que você configurou. A chamada de retorno ocorre em uma porta local que o agente de codificação abre temporariamente. firewalls ou VPNs podem às vezes bloquear isso.

### A troca de tokens falha

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve anunciar suporte S256 para que o PKCE funcione. O Glossia inclui isso por padrão.

### O agente não consegue alcançar o servidor

Para desenvolvimento local, certifique-se de que o servidor Phoenix esteja em execução (`mix phx.server`) e escutando na porta esperada (padrão: 4050). O endpoint MCP deve ser acessível do processo do agente.