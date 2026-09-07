%{
  title: "Tokens da conta",
  summary: "Crie e gerencie os tokens da conta para se autenticar com a Glossia API.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---
Tokens de conta fornecem uma maneira simples de autenticar requisições de API sem passar pelo fluxo completo de OAuth. Eles são ideais para scripts, pipelines CI/CD e automação pessoal.

## Criando um token

1. Faça login no Glossia e navegue até o seu painel da conta.
2. Abra o **API** Seção da barra lateral.
3. Clique **Tokens de conta**, em seguida **Novo token**.
4. Dê ao token um descritivo **nome** (por exemplo, "deploy CI" ou "acesso CLI").
5. Escolha os **escopos** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe-o em branco para um token que nunca expira.
7. Clique **Criar token**.

Após a criação, o valor completo do token é exibido. **uma vez**. Copie-o imediatamente e armazene-o com segurança. Você não conseguirá visualizar o valor completo novamente.

## Usando um token

Inclua o token no `Authorization` cabeçalho de suas requisições HTTP:

    Authorization: Bearer glsa_abc123def456...

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens de conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authentication) como tokens OAuth. Os escopos do token definem o conjunto máximo de ações que ele pode executar, e as políticas de nível de recurso ainda se aplicam com base nas relações da sua conta.

## Formato do token

Todos os tokens de conta começam com o `glsa_` prefixo seguido por uma string hexadecimal aleatória. Esse prefixo facilita identificar tokens do Glossia em logs e varredores de segredos.

## Escopos

Os tokens de conta suportam os mesmos escopos que os tokens OAuth. Veja a [referência de escopos](/docs/reference/apis/authentication) para a lista completa.

Ao criar um token, selecione apenas os escopos que seu caso de uso requer. Por exemplo:

- Uma integração somente leitura precisa de `project:read` e `voice:read`.
- Um pipeline de CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros da organização precisa `members:read` e `members:write`,.

## Gerenciamento de tokens

### Visualização de tokens

A **tokens da conta** página lista todos os tokens ativos com seu nome, escopos, data de última utilização e vencimento. Tokens que nunca foram usados exibem "Nunca" na coluna de última utilização.

### Edição de tokens

Clique no nome de um token para editar seu **nome** e **descrição**. Permissões e vencimento não podem ser alterados após a criação. Se você precisar de permissões diferentes, crie um novo token e revogue o antigo.

### Revogando tokens

Para revogar um token, clique **Revogar** na lista de tokens ou abra a página de edição do token e use o **Revogar token** botão na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca comita tokens no controle de versão.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize os escopos.** Conceda apenas as permissões que o token realmente precisa.
- **Rotacione regularmente.** Crie novos tokens e revoque os antigos de forma agendada.
- **Monitore o uso.** Verifique periodicamente a data "de último uso". Revogue tokens que não estão mais em uso.
- **Use um token por integração.** Desta forma, revogar um token não interfere em outros fluxos de trabalho.

## Gerenciamento de API

Você também pode gerenciar tokens da conta por meio da API REST e do servidor MCP.

### API REST

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`, `create_token`e `revoke_token` ferramentas que espelham a API REST.