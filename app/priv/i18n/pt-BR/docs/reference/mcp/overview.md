%{
  title: "Visão Geral",
  summary:
    "Conecte agentes de codificação aos seus projetos Glossia por meio do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---

O Glossia expõe um servidor [Model Context Protocol](https://modelcontextprotocol.io) (MCP) que permite que agentes de codificação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), portanto qualquer cliente compatível com MCP pode autenticar-se sem configuração manual de credenciais.

## O que o servidor MCP fornece

Uma vez conectado, um agente de codificação pode listar contas e projetos, criar projetos, gerenciar membros e convites de organização, ler ou atualizar configurações de voz e glossário, e gerenciar modelos de conta e tokens, dependendo de suas permissões.

O servidor atualmente não expõe ferramentas para iniciar traduções ou revisões, ou para verificar o status de tradução por arquivo. Consulte a [referência de ferramentas](/docs/reference/mcp) para as ferramentas disponíveis.

## URL do Servidor

Conecte-se ao serviço hospedado do Glossia em `https://glossia.ai/mcp`. O Glossia executa e mantém este endpoint; você só configura a conexão no seu agente de codificação.

## Fluxo de autenticação

O servidor MCP usa o fluxo de código de autorização OAuth 2.1 padrão com PKCE. Não é necessário criar clientes OAuth manualmente. O fluxo funciona assim:

1. O agente descobre o Glossia através de `https://glossia.ai/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth pelo endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Depois que você aprovar, o agente recebe um token de acesso e o anexa a todas as solicitações MCP

## Adicionar Glossia a um agente de codificação

### OpenAI Codex

Seguindo o [guia de conexão do Codex](https://developers.openai.com/codex/mcp), adicione o servidor ao seu arquivo de configuração do Codex em `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Então execute o login OAuth:

```bash
codex mcp login glossia
```

Seu navegador se abrirá para autenticação. Depois de aprovar, o Codex armazena o token localmente e o usa para sessões futuras.

Para verificar a conexão:

```bash
codex mcp list
```

### Claude Code

Adicione o servidor hospedado com o comando documentado no [guia de conexão do Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Execute `/mcp` dentro do Claude Code e siga o fluxo de autenticação do navegador.

### Outros clientes MCP

Um cliente deve suportar o [fluxo de autorização do Model Context Protocol](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado pelo Glossia. A conexão requer:

- **Transporte**: HTTP Streamable
- **Descoberta**: O cliente deve suportar OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Indique o cliente para `https://glossia.ai/mcp` e deixe-o lidar com descoberta e registro automaticamente.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP usam para inicializar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados de recurso protegido (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth impõem limites de taxa para prevenir abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com um cabeçalho `Retry-After`.

## Solução de problemas

### O registro falha com "invalid_client_metadata"

O endpoint de registro dinâmico apenas aceita valores específicos `token_endpoint_auth_method`,. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o que o Glossia gerencia automaticamente ao reverter para métodos de autenticação padrão com PKCE enforcement.

### "Chamada de callback OAuth inválida" após a aprovação

Confirme que seu agente de codificação pode acessar `https://glossia.ai`. O callback ocorre em uma porta local que seu agente de codificação abre temporariamente em seu computador. O Glossia permanece hospedado; este ouvinte local pertence ao seu agente. Firewalls ou redes privadas virtuais podem às vezes bloquear o callback.

### A troca de token falha

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve anunciar suporte S256 para que o PKCE funcione. O Glossia inclui isso automaticamente.

### O agente não consegue alcançar o servidor

Verifique se o endpoint configurado é `https://glossia.ai/mcp` e que sua rede permite que seu agente de codificação o alcance. Se o serviço hospedado permanecer indisponível, entre em contato com o suporte do Glossia.
