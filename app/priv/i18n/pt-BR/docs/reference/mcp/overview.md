%{
  title: "Visão geral",
  summary:
    "Conecte os agentes de codificação aos seus projetos Glossia por meio do Model Context Protocol.",
  category: "Referência",
  subcategory: "mcp",
  order: 1
}
---
Glossia expõe um [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server que permite que agentes de codificação interajam com seus projetos de localização. O servidor implementa OAuth 2.1 com PKCE e Registro Dinâmico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), de modo que qualquer cliente compatível com MCP possa autenticar sem configuração manual de credenciais.

## O que o servidor MCP fornece

Assim que conectado, um agente de codificação pode listar contas e projetos, criar projetos, gerenciar membros e convites da organização, ler ou atualizar configurações de voz e glossário e gerenciar modelos e tokens de conta, sujeito às suas permissões.

O servidor atualmente não expõe ferramentas para iniciar traduções ou revisões, nem para inspecionar o status de tradução por arquivo. Veja o [referência de ferramenta](/docs/reference/mcp) para as ferramentas disponíveis.

## URL do servidor

Conecte-se ao serviço hospedado da Glossia em `https://glossia.ai/mcp`. Glossia opera e mantém este endpoint; você apenas configura a conexão no seu agente de codificação.

## Fluxo de autenticação

O servidor MCP utiliza o fluxo padrão OAuth 2.1 de código de autorização com PKCE. Você não precisa criar clientes OAuth manualmente. O fluxo funciona assim:

1. O agente descobre a Glossia através de `https://glossia.ai/.well-known/oauth-authorization-server`
2. Ele se registra como um cliente OAuth via o endpoint de registro dinâmico
3. Ele abre o seu navegador para login e consentimento
4. Após você aprovar, o agente recebe um token de acesso e o anexa a todas as requisições MCP

## Adicionando Glossia a um agente de programação

### OpenAI Codex

Seguindo o [guia de conexão do Codex](https://developers.openai.com/codex/mcp), adicione o servidor ao seu arquivo de configuração do Codex em `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Em seguida, execute o login OAuth:

```bash
codex mcp login glossia
```

Seu navegador será aberto para autenticação. Após a aprovação, o Codex armazenará o token localmente e o usará para sessões futuras.

Para verificar a conexão:

```bash
codex mcp list
```

### Claude Code

Adicione o servidor hospedado com o comando documentado em [guia de conexão do Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Executar `/mcp` dentro do Claude Code e siga o fluxo de autenticação do navegador.

### Outros clientes MCP

O cliente deve suportar o [fluxo de autorização do Model Context Protocol](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado pelo Glossia. A conexão requer:

- **Transporte**: Streamable HTTP
- **Descoberta**: O cliente deve suportar Metadados de Recursos Protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinâmico de Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Fluxo de autenticação**: Código de autorização com PKCE (S256)

Aponte o cliente para `https://glossia.ai/mcp` e deixe-o lidar com a descoberta e o registro automaticamente.

## Endpoints de descoberta

O servidor publica dois documentos de metadados que os clientes MCP usam para inicializar o fluxo OAuth:

| Endpoint | Descrição |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadados do servidor de autorização (endpoints, tipos de concessão suportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadados de recurso protegido (escopos, servidores de autorização) |

## Limites de taxa

Os endpoints OAuth impõem limites de taxa para prevenir abusos:

| Endpoint | Limite de taxa |
|---|---|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |

Quando um limite de taxa é excedido, o servidor retorna HTTP 429 com um `Retry-After` cabeçalho.

## Solução de problemas

### O registro falha com "invalid\_client\_metadata"

O endpoint de registro dinâmico aceita apenas específicos `token_endpoint_auth_method` valores. Clientes públicos (a maioria dos agentes de codificação) devem enviar `"none"`, o que o Glossia gerencia automaticamente, recorrendo aos métodos de autenticação padrão com imposição do PKCE.

### "Chamada de retorno inválida do OAuth" após a aprovação

Confirme que seu agente de codificação pode alcançar `https://glossia.ai`, a chamada de retorno ocorre em uma porta local que o agente de codificação abre temporariamente em seu computador. O Glossia permanece hospedado; este ouvinte local pertence ao seu agente. Firewalls ou redes privadas virtuais podem às vezes bloquear a chamada de retorno.

### Falha na troca de token

Verifique que o `code_challenge_methods_supported` o campo está presente no metadado do servidor de autorização. O servidor deve anunciar suporte ao S256 para o PKCE funcionar. A Glossia inclui isso por padrão.

### O agente não consegue alcançar o servidor

Verifique que o endpoint configurado está `https://glossia.ai/mcp` e que sua rede permita ao seu agente de codificação acessá-lo. Se o serviço hospedado permanecer indisponível, entre em contato com o suporte da Glossia.