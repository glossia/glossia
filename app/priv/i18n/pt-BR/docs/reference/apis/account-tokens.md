%{
  title: "Tokens da conta",
  summary: "Crie e gerencie tokens da conta para autenticar com a API do Glossia.",
  category: "Referência",
  subcategory: "APIs",
  order: 3
}
---

Tokens de conta fornecem uma maneira simples de autenticar solicitações de API sem passar por todo o fluxo de OAuth. Eles são ideais para scripts, pipelines de CI/CD e automação pessoal.

## Criação de um token

1. Faça login no Glossia e navegue até o painel da sua conta.
2. Abra a seção **API** da barra lateral.
3. Clique em **Tokens de conta**, em seguida em **Novo token**.
4. Dê ao token um **nome** descritivo (por exemplo, "CI deploy" ou "CLI access").
5. Escolha os **escopos** necessários pelo token. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe em branco para um token que não expira.
7. Clique em **Criar token**.

Após a criação, o valor completo do token é exibido **uma única vez**. Copie-o imediatamente e armazene-o com segurança. Você não poderá ver o valor completo novamente.

## Usando um token

Inclua o token no cabeçalho `Authorization` das suas solicitações HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens de conta seguem o mesmo [modelo de autenticação](/docs/reference/apis/authorization) dos tokens OAuth. Os escopos do token definem o conjunto máximo de ações que ele pode executar, e as políticas de nível de recurso continuam sendo aplicadas com base nas relações da sua conta.

## Formato do token

Todos os tokens de conta começam com o prefixo `glsa_` seguido de uma cadeia hexadecimal aleatória. Este prefixo facilita a identificação de tokens do Glossia em logs e scanners de segredos.

## Escopos

Tokens de conta suportam os mesmos escopos dos tokens OAuth. Consulte a [referência de escopos](/docs/reference/apis/authorization) para a lista completa.

Ao criar um token, selecione apenas os escopos exigidos pelo seu caso de uso. Por exemplo:

- Uma integração de apenas leitura precisa de `project:read` e `voice:read`.
- Um pipeline de CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros da organização precisa de `members:read` e `members:write`.

## Gerenciamento de tokens

### Visualização de tokens

A página **Tokens de conta** lista todos os tokens ativos com seu nome, escopos, data do último uso e expiração. Tokens que nunca foram usados mostram "Nunca" na coluna do último uso.

### Edição de tokens

Clique no nome de um token para editar seu **nome** e **descrição**. Os escopos e a expiração não podem ser alterados após a criação. Se precisar de escopos diferentes, crie um novo token e revogue o antigo.

### Revogação de tokens

Para revogar um token, clique em **Revogar** na lista de tokens ou abra a página de edição do token e use o botão **Revogar token** na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene seus tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca faça commit dos tokens ao controle de código fonte.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize os escopos.** Conceda apenas as permissões que o token realmente precise.
- **Renove-os regularmente.** Crie novos tokens e revogue os antigos em um cron.
- **Monitore o uso.** Verifique periodicamente a data do "último uso". Revogue tokens que não são mais utilizados.
- **Use um token por integração.** Dessa forma, revogar um token não quebra outros fluxos de trabalho.

## Gerenciamento de API

Você também pode gerenciar tokens de conta por meio da REST API e do servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`, `create_token` e `revoke_token` que espelham a REST API.
