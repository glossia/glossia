%{
  title: "Tokens da conta",
  summary: "Criar e gerenciar tokens da conta para autenticar na API da Glossia.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---
Tokens de conta oferecem uma maneira simples de autenticar solicitações de API sem precisar passar pelo fluxo completo do OAuth. São ideais para scripts, pipelines CI/CD e automação pessoal.

## Criação de um token

1. Faça login no Glossia e navegue até o painel da sua conta.
2. Abra o **API** seção na barra lateral.
3. Clique **Tokens de conta**, então **Novo token**.
4. Forneça ao token um nome **nome** (por exemplo, "CI deploy" ou "acesso CLI").
5. Escolha os **escopos** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de expiração** ou deixe-o vazio para um token que nunca expira.
7. Clique **Criar token**.

Após a criação, o valor completo do token é exibido **uma vez**. Copie-o imediatamente e guarde-o com segurança. Você não verá mais o valor completo.

## Uso de um token

Inclua o token no `Authorization` cabeçalho das suas requisições HTTP:

    Authorization: Bearer glsa_abc123def456...

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens de conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authentication) como tokens OAuth. Os escopos do token definem o conjunto máximo de ações que ele pode executar, e as políticas em nível de recurso ainda se aplicam com base nas relações da sua conta.

## Formato do token

Todos os tokens de conta começam com o `glsa_` prefixo seguido por uma string hexadecimal aleatória. Este prefixo facilita a identificação de tokens Glossia em logs e scanners de segredos.

## Escopos

Os tokens de conta suportam os mesmos escopos que os tokens OAuth. Consulte a [referência de escopos](/docs/reference/apis/authentication) para a lista completa.

Ao criar um token, selecione apenas os escopos que o seu caso de uso exige. Por exemplo:

- Uma integração de somente leitura precisa de `project:read` e `voice:read`.
- Um pipeline de CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros da organização precisa `members:read` e `members:write`.

## Gerenciando tokens

### Visualizando tokens

A **tokens da conta** página lista todos os tokens ativos com nome, escopos, data do último uso e data de vencimento. Tokens que nunca foram utilizados mostram "Nunca" na coluna do último uso.

### Editando tokens

Clique no nome do token para editar seu **nome** e **descrição**. Escopos e expiração não podem ser alterados após a criação. Se precisar de escopos diferentes, crie um novo token e revoque o antigo.

### Revogando tokens

Para revogar um token, clique **Revogar** na lista de tokens ou abra a página de edição do token e use o **Revogar token** botão na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Armazene tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca comita tokens para o controle de versão.
- **Use tokens de curta duração.** Defina uma data de expiração sempre que possível.
- **Minimize os escopos.** Conceda apenas as permissões que o token realmente precisa.
- **Rota regularmente.** Crie novos tokens e revogue os antigos em um cronograma.
- **Monitore o uso.** Verifique a data de "último uso" periodicamente. Revogue os tokens que não estão mais em uso.
- **Use um token por integração.** Desta forma, revogar um token não interrompe outros fluxos de trabalho.

## Gerenciamento de API

Você também pode gerenciar tokens de conta por meio do REST API e do servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`O documento remontado anteriormente falhou na validação: a recuperação de texto literal Markdown retornou JSON inválido `create_token`, e `revoke_token` ferramentas que espelham a API REST.