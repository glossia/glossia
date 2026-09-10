%{
  title: "Tokens de conta",
  summary: "Crie e gerencie tokens de conta para autenticar com a API da Glossia.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---
Tokens de conta fornecem uma maneira simples de autenticar solicitações de API sem passar pelo fluxo completo do OAuth. São ideais para scripts, pipelines de CI/CD e automação pessoal.

## Criando um token

1. Faça login no Glossia e navegue até o painel de conta.
2. Abra a **API** seção na barra lateral.
3. Clique **Tokens de conta**, então **Novo token**.
4. Dê ao token um descritivo **nome** (por exemplo, "CI deploy" ou "CLI access")
5. Escolha os **escopos** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe em branco para um token que nunca expira.
7. Clique **Criar token**.

Após a criação, o valor completo do token é exibido **uma vez**. Copie-o imediatamente e armazene-o com segurança. Você não poderá ver o valor completo novamente.

## Usando um token

Inclua o token no `Authorization` cabeçalho das suas solicitações HTTP:

    Authorization: Bearer glsa_abc123def456...

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens da conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authentication) como tokens OAuth. Os escopos do token definem o conjunto máximo de ações que ele pode executar, e as políticas de nível de recurso continuam aplicadas com base nas relações da sua conta.

## Formato do token

Todos os tokens de conta começam com o `glsa_` prefixo seguido por uma string hexadecimal aleatória. Esse prefixo facilita a identificação de tokens da Glossia em logs e scanners de segredos.

## Escopos

Tokens de conta suportam os mesmos escopos que os tokens OAuth. Veja a [referência de escopos](/docs/reference/apis/authentication) para a lista completa.

Ao criar um token, selecione apenas os escopos que seu caso de uso requer. Por exemplo:

- Uma integração somente de leitura precisa de `project:read` e `voice:read`.
- Um pipeline de CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros de organização precisa `members:read` e `members:write`.

## Gerenciamento de tokens

### Visualização de tokens

A **Tokens da conta** página lista todos os tokens ativos com seu nome, escopos, data de última utilização e expiração. Tokens que nunca foram utilizados exibem "Nunca" na coluna de última utilização.

### Editando tokens

Clique no nome do token para editar o **nome** e **descrição**. Escopos e expiração não podem ser alterados após a criação. Se precisar de escopos diferentes, crie um novo token e revogue o antigo.

### Revogando tokens

Para revogar um token, clique **Revogar** na lista de tokens ou abra a página de edição do token e utilize o **Revogar token** botão na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca faça commit de tokens no controle de versão.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize escopos.** Conceda apenas as permissões que o token realmente precisa.
- **Troque-os regularmente.** Crie novos tokens e revogue os antigos periodicamente.
- **Monitore o uso.** Verifique a data de "último uso" periodicamente. Revogue os tokens que não estão mais em uso.
- **Use um token por integração.** Dessa forma, revogar um token não interrompe outros fluxos de trabalho.

## Gerenciamento de API

Você também pode gerenciar tokens da conta via REST API e servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`, `create_token`, e `revoke_token` ferramentas que refletem a API REST.