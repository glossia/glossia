%{
  title: "Configure um provedor de modelos",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "Passo a passo",
  order: 3
}
---
A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite um handle único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salve o modelo.

O handle permanece estável mesmo quando você alterar posteriormente o modelo do provedor subjacente. O primeiro modelo adicionado a uma conta se torna o padrão.

## Referencie o modelo de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha o modelo a ser usado por padrão

Quando `L10N.md` omite `model`, Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Definir como padrão**.

Para comportamento previsível entre vários modelos, referencie explicitamente uma alça em `L10N.md`.

Você pode colocar um `model` alça em um aninhado `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para um único idioma de destino. O Glossia usa a configuração mais próxima aplicável para cada documento e idioma. Não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução para com um erro. Não recorre para outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o identificador do modelo. Digite uma nova chave de provedor e salve. Deixar o campo de chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam ser alterados.