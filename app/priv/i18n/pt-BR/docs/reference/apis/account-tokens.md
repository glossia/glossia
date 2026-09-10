%{
  title: "Tokens da conta",
  summary: "Crie e gerencie tokens da conta para autenticar na API da Glossia.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---
Tokens de conta fornecem uma maneira simples de autenticar solicitações de API sem passar pelo fluxo completo de OAuth. Eles são ideais para scripts, pipelines de CI/CD e automação pessoal.

## Criando um token

1. Faça login na Glossia e navegue até o painel da sua conta.
2. Abra o **API** seção na barra lateral.
3. Clique **Tokens de conta**, então **Novo token**.
4. Dê ao token um descritivo **nome** (por exemplo, \\"CI deploy\\" ou \\"CLI acesso\\").
5. Escolha os **escopos** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe-o em branco para um token que nunca expira.
7. Clique **Criar token**.

Após a criação, o valor completo do token é exibido **uma vez**. Copie-o imediatamente e armazene-o com segurança. Não será mais possível ver o valor completo novamente.

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

Todos os tokens de conta começam com o `glsa_` prefixo seguido de uma string hexadecimal aleatória. Esse prefixo facilita a identificação dos tokens do Glossia em logs e scanners de segredos.

## Escopos

Os tokens de conta suportam os mesmos escopos dos tokens OAuth. Veja a [referência de escopos](/docs/reference/apis/authentication) para a lista completa.

Ao criar um token, selecione apenas os escopos que seu caso de uso exige. Por exemplo:

- Uma integração somente leitura precisa de `project:read` e `voice:read`.
- Um pipeline CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia os membros da organização precisa `members:read` e `members:write`.

## Gerenciamento de tokens

### Visualização de tokens

A **Tokens da conta** página lista todos os tokens ativos com seu nome, escopos, data de último uso e expiração. Os tokens que nunca foram usados exibem "Nunca" na coluna de último uso.

### Editando tokens

Clique no nome do token para editar o seu **nome** e **descrição**. Os escopos e a expiração não podem ser alterados após a criação. Se você precisar de escopos diferentes, crie um novo token e revogue o antigo.

### Revogando tokens

Para revogar um token, clique **Revogar** na lista de tokens ou abrir a página de edição do token e usar o **Revogar token** botão na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene tokens de forma segura.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca comite tokens no controle de versão.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize escopos.** Conceda apenas as permissões que o token realmente precisa.
- **Rotacione periodicamente.** Crie novos tokens e revogue os antigos segundo um cronograma.
- **Monitore o uso.** Verifique a data \\"do último uso\\" periodicamente. Revogue os tokens que não estão mais em uso.
- **Use um token por integração.** Desta forma, revogar um token não interrompe outros fluxos de trabalho.

## Gerenciamento de API

Você também pode gerenciar os tokens da conta por meio da REST API e do servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`, `create_token`e `revoke_token` ferramentas que espelham a REST API.