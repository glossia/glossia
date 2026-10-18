%{
  title: "Visão geral",
  summary:
    "Conecte agentes de codificação aos seus projetos Glossia através do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---

A Glossia expõe um servidor de [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) (MCP) que permite que agentes de codificação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), permitindo que qualquer cliente compatível com o MCP se autentique sem a configuração manual de credenciais.

## O que o servidor MCP fornece

Depois de conectado, um agente de codificação pode listar contas e projetos, criar projetos, gerenciar membros e convites da organização, ler ou atualizar configurações de voz e glossário, e gerenciar modelos de conta e tokens, conforme as permissões dele.

O servidor atualmente não expõe ferramentas para iniciar traduções ou revisões, ou para inspecionar o status de tradução por arquivo. Consulte a [referência de ferramentas](/docs/reference/mcp) para as ferramentas disponíveis.

## URL do Servidor

Conecte-se ao serviço hospedado da Glossia em `https://glossia.ai/mcp`. A Glossia executa e mantém este endpoint; você só configura a conexão no seu agente de codificação.

## Fluxo de autenticação

O servidor MCP usa o fluxo de código de autorização OAuth 2.1 padrão com PKCE. Você não precisa criar clientes OAuth manualmente. O fluxo funciona da seguinte maneira:

1. O agente descobre a Glossia através de `https://glossia.ai/.well-known/oauth-authorization-server`
2. Ele registra-se como um cliente OAuth através do endpoint de registro dinâmico
3. Ele abre seu navegador para login e consentimento
4. Depois que você aprovar, o agente recebe um token de acesso e o anexa a todas as solicitações MCP

## Adicionando a Glossia a um agente de codificação

### OpenAI Codex

Seguindo o [guia de conexão do Codex](https://developers.openai.com/codex/mcp), adicione o servidor ao arquivo de configuração do Codex em `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Em seguida, execute o login OAuth:

```bash
codex mcp login glossia
```

Seu navegador abrirá para autenticação. Depois de aprovar, o Codex armazena o token localmente e o usa para futuras sessões.

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

Um cliente deve suportar o [fluxo de autorização do Protocolo de Contexto do Modelo](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado pela Glossia. A conexão requer:

- **Transporte**: HTTP Streamável
- **Descoberta**: O cliente deve suportar os Metadados de Recurso Protegido OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para `https://glossia.ai/mcp` e deixe-o lidar automaticamente com a descoberta e o registro.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP usam para inicializar o fluxo de OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados do recurso protegido (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth aplicam limites de taxa para evitar abusos:

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com um `Retry-After` cabeçalho.

## Solução de problemas

### Registro falha com "invalid_client_metadata"

O endpoint de registro dinâmico aceita apenas valores específicos `token_endpoint_auth_method`. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, que a Glossia trata automaticamente ao retornar aos métodos de autenticação padrão com PKCE.

### "Callback OAuth inválido" após aprovar

Confirme que seu agente de codificação pode acessar `https://glossia.ai`. O callback ocorre em uma porta local que o agente de codificação abre temporariamente em seu computador. A Glossia continua hospedada; este ouvinte local pertence ao seu agente. Firewalls ou redes privadas virtuais podem às vezes bloquear o callback.

### A troca de token falha

Verifique se o campo `code_challenge_methods_supported` está presente nos metadados do servidor de autorização. O servidor deve exibir o suporte S256 para PKCE para funcionar. A Glossia inclui isso por padrão.

### O agente não pode chegar ao servidor

Verifique se o endpoint configurado é `https://glossia.ai/mcp` e que sua rede permite que seu agente de codificação o acesse. Se o serviço hospedado continuar indisponível, entre em contato com o suporte da Glossia.
