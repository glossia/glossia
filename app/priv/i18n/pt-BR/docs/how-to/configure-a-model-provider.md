%{
  title: "Configure um provedor de modelo",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "tutorial",
  order: 3
}
---
A configuração do projeto e as execuções de tradução usam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Insira um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte de um nome de provedor ou modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salvar o modelo.

O identificador permanece estável, mesmo que você altere posteriormente o modelo do provedor subjacente. O primeiro modelo adicionado a uma conta torna-se o padrão.

## Referenciar o modelo de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Selecione o modelo a ser usado por padrão

Quando `L10N.md` omite `model`, Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Definir como padrão**.

Para um comportamento previsível em vários modelos, referencie explicitamente um handle em `L10N.md`.

Você pode colocar uma diferente `model` alça em um aninhado `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para um único idioma de destino. O Glossia usa a configuração mais próxima aplicável para cada documento e idioma. Ele não distribui automaticamente o trabalho entre os modelos configurados.

Se um handle explícito não existir na conta, a tradução para com erro. Ela não recue para outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o handle do modelo. Digite uma nova chave de provedor e salve. Deixar o campo de chave vazio mantém a chave atual.

Repositórios que referenciam o handle não precisam mudar.