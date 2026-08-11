%{
  title: "Tokens da conta",
  summary: "Crie e gerencie tokens da conta para autenticação com a API da Glossia.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---
Os tokens de conta oferecem uma forma simples de autenticar solicitações à API sem passar por todo o fluxo OAuth. Eles são ideais para scripts, pipelines de CI/CD e automações pessoais.

## Como criar um token

1. Entre no Glossia e acesse o painel da sua conta.
2. Abra a seção **API** na barra lateral.
3. Clique em **Tokens de conta** e depois em **Novo token**.
4. Dê ao token um **nome** descritivo, por exemplo, "Implantação de CI" ou "Acesso pela CLI".
5. Escolha os **escopos** necessários para o token. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe o campo em branco para criar um token que nunca expira.
7. Clique em **Criar token**.

Após a criação, o valor completo do token será exibido **uma única vez**. Copie-o imediatamente e armazene-o com segurança. Não será possível visualizar o valor completo novamente.

## Como usar um token

Inclua o token no cabeçalho `Authorization` das suas solicitações HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens de conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authentication) dos tokens OAuth. Os escopos do token definem o conjunto máximo de ações que ele pode executar, e as políticas no nível dos recursos continuam sendo aplicadas de acordo com os vínculos da sua conta.

## Formato do token

Todos os tokens de conta começam com o prefixo `glsa_`, seguido por uma sequência hexadecimal aleatória. Esse prefixo facilita a identificação dos tokens do Glossia em logs e verificadores de segredos.

## Escopos

Os tokens de conta são compatíveis com os mesmos escopos dos tokens OAuth. Consulte a [referência de escopos](/docs/reference/apis/authentication) para ver a lista completa.

Ao criar um token, selecione apenas os escopos exigidos pelo seu caso de uso. Por exemplo:

- Uma integração somente para leitura precisa de `project:read` e `voice:read`.
- Um pipeline de CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros da organização precisa de `members:read` e `members:write`.

## Como gerenciar tokens

### Como visualizar tokens

A página **Tokens de conta** lista todos os tokens ativos com seus respectivos nomes, escopos, datas da última utilização e datas de expiração. Os tokens que nunca foram usados exibem "Nunca" na coluna de última utilização.

### Como editar tokens

Clique no nome de um token para editar seu **nome** e sua **descrição**. Os escopos e a expiração não podem ser alterados após a criação. Caso precise de escopos diferentes, crie um novo token e revogue o antigo.

### Como revogar tokens

Para revogar um token, clique em **Revogar** na lista de tokens ou abra a página de edição do token e use o botão **Revogar token** na zona de perigo. Tokens revogados deixam de funcionar imediatamente e não podem ser restaurados.

## Práticas recomendadas de segurança

- **Armazene os tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca faça commit de tokens no controle de versão.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize os escopos.** Conceda apenas as permissões de que o token realmente precisa.
- **Faça a rotação regularmente.** Crie novos tokens e revogue os antigos conforme uma programação.
- **Monitore o uso.** Verifique periodicamente a data da "última utilização". Revogue os tokens que não estiverem mais em uso.
- **Use um token por integração.** Dessa forma, a revogação de um token não interrompe outros fluxos de trabalho.

## Gerenciamento pela API

Também é possível gerenciar tokens de conta por meio da API REST e do servidor MCP.

### API REST

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe as ferramentas `list_tokens`, `create_token` e `revoke_token`, que espelham a API REST.