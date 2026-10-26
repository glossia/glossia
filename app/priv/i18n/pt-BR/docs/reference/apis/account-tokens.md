%{
  title: "Tokens de conta",
  summary: "Criar e gerenciar tokens de conta para autenticação com a API do Glossia.",
  category: "Referência",
  subcategory: "APIs",
  order: 3
}
---

Os tokens de conta fornecem uma maneira simples de autenticar solicitações de API sem passar pelo fluxo completo do OAuth. São ideais para scripts, pipelines CI/CD e automação pessoal.

## Criando um token

1. Faça login no Glossia e navegue até seu painel de conta.
2. Abra a seção **API** no menu lateral.
3. Clique em **Tokens da conta**, em seguida, em **Novo token**.
4. Dê ao token um **nome** descritivo (por exemplo, "CI deploy" ou "CLI access").
5. Escolha os **escopos** que o token precisa. Conceda apenas as permissões mínimas necessárias.
6. Defina uma **data de validade** ou deixe em branco para um token que nunca expira.
7. Clique em **Criar token**.

Após a criação, o valor completo do token é exibido **uma única vez**. Copie-o imediatamente e guarde-o com segurança. Você não verá o valor completo novamente.

## Usando um token

Inclua o token no cabeçalho `Authorization` das suas requisições HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por exemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Os tokens de conta seguem o mesmo [modelo de autorização](/docs/reference/apis/authorization) que os tokens OAuth. Os escopos do token definem o conjunto máximo de ações que podem realizar, e as políticas de nível de recurso continuam a se aplicar com base nas conexões da sua conta.

## Formato do token

Todos os tokens de conta começam com o prefixo `glsa_` seguido por uma string hexadecimal aleatória. Este prefixo facilita a identificação dos tokens do Glossia em logs e varredores de segredos.

## Escopos

Os tokens de conta suportam os mesmos escopos que os tokens OAuth. Consulte a [referência de escopos](/docs/reference/apis/authorization) para a lista completa.

Ao criar um token, selecione apenas os escopos que seu caso de uso exige. Por exemplo:

- Uma integração somente leitura precisa de `project:read` e `voice:read`.
- Uma pipeline CI que cria projetos precisa de `project:read` e `project:write`.
- Um script que gerencia membros de organização precisa de `members:read` e `members:write`.

## Gerenciamento de tokens

### Visualização de tokens

A página **Tokens da conta** lista todos os tokens ativos com seu nome, escopos, data de uso último e expiração. Tokens que nunca foram usados mostram "Nunca" na coluna de uso último.

### Edição de tokens

Clique no nome de um token para editar seu **nome** e **descrição**. Escopos e data de validade não podem ser alterados após a criação. Se precisar de diferentes escopos, crie um novo token e revogue o antigo.

### Revogação de tokens

Para revogar um token, clique em **Revogar** na lista de tokens ou abra a página de edição do token e use o botão **Revogar token** na zona de perigo. Tokens revogados param de funcionar imediatamente e não podem ser restaurados.

## Melhores práticas de segurança

- **Guarde tokens com segurança.** Use variáveis de ambiente ou um gerenciador de segredos. Nunca comprometa tokens em controle de versão.
- **Use tokens de curta duração.** Defina uma data de validade sempre que possível.
- **Minimize escopos.** Conceda apenas as permissões que o token realmente precisa.
- **Rotacione regularmente.** Crie novos tokens e revogue os antigos conforme um cronograma.
- **Monitore o uso.** Verifique a data de "uso último" periodicamente. Revogue tokens que não são mais utilizados.
- **Use um token por integração.** Dessa forma, revogar um token não quebra outros fluxos de trabalho.

## Gestão de API

Você também pode gerenciar tokens de conta por meio do REST API e servidor MCP.

### REST API

| Método | Endpoint | Descrição |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens ativos |
| `POST` | `/api/tokens` | Criar um novo token |
| `DELETE` | `/api/tokens/:id` | Revogar um token |

### MCP

O servidor MCP expõe `list_tokens`, `create_token` e `revoke_token` ferramentas que espelham o REST API.
