%{
  title: "Tokens de conta",
  summary: "Crie e gerencie tokens de conta para autenticar com a API do Glossia.",
  category: "referência",
  subcategory: "APIs",
  order: 3
}
---

Tokens de conta oferecem uma maneira simples de autenticar requisições de API sem passar pelo fluxo completo de OAuth. São ideais para scripts, pipelines de CI/CD e automação pessoal.

## Criando um token

1. Faça login na Glossia e navegue para o painel de sua conta.
2. Abra a seção **API** do menu lateral.
3. Clique em **Tokens de conta**, depois em **Novo token**.
4. Dê ao token um **nome** descritivo (por exemplo, "CI deploy" ou "CLI access").
5. Escolha os **scopes** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe em branco para um token que nunca expira.
7. Clique em **Criar token**.

Após a criação, o valor completo do token é exibido **uma vez**. Copie-o imediatamente e armazenem-no com segurança. Não será possível ver o valor completo novamente.

## Usando um token

Inclua o token no `Authorization` cabeçalho das suas requisições HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Tokens de conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authorization) que os tokens OAuth. Os scopes do token definem o conjunto máximo de ações que ele pode executar, e políticas de nível de recurso ainda se aplicam com base nas relações da sua conta.

## Formato do token

Todos os tokens de conta começam com o prefixo `glsa_` seguido de uma sequência hexadecimal aleatória. Este prefixo facilita identificar tokens da Glossia em logs e scanners de segredos.

## Scopes

Tokens de conta suportam os mesmos scopes que os tokens OAuth. Consulte a [referência de scopes](/docs/reference/apis/authorization) para a lista completa.

Ao criar um token, selecione apenas os scopes que o uso que exige. Por exemplo:

- Uma integração somente leitura precisa `project:read` e `voice:read`.
- Um pipeline CI que cria projetos precisa `project:read` e `project:write`.
- Um script que gerencia membros de organização precisa `members:read` e `members:write`.

## Gerenciamento de tokens

### Visualizando tokens

A página **Tokens de conta** lista todos os tokens ativos com seu nome, scopes, data do último uso e expiração. Tokens que nunca foram usados mostram "Nunca" na coluna do último uso.

### Editando tokens

Clique no nome de um token para editar seu **nome** e **descrição**. Scopes e expiração não podem ser alterados após a criação. Se precisar de scopes diferentes, crie um novo token e revogue o antigo.

### Revogando tokens

Para revogar um token, clique em **Revogar** na lista de tokens ou abra a página de edição do token e use o botão **Revogar token** na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca commit tokens ao controle de versão.
- **Use tokens de vida curta.** Defina uma data de expiração sempre que possível.
- **Minimize scopes.** Conceda apenas as permissões que o token realmente precisa.
- **Rotacione regularmente.** Crie novos tokens erevogue-os antigos em um cronograma.
- **Monitore o uso.** Verifique a data "Último uso" periodicamente. Revogue tokens que não estão mais sendo utilizados.
- **Use um token por integração.** Dessa forma, revogar um token não quebra outros fluxos de trabalho.

## Gestão de API

Você também pode gerenciar tokens de conta através da REST API e servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe as ferramentas `list_tokens`, `create_token` e `revoke_token` que espelham a REST API.
