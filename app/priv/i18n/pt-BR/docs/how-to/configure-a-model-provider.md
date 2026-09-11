%{
  title: "Configurar um provedor de modelo",
  summary: "Adicionar um modelo de conta e referenciá-lo com segurança a partir de repositórios.",
  category: "Tutorial",
  order: 3
}
---
A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave do provedor.
6. Salve o modelo.

O identificador permanece estável mesmo se você alterar posteriormente o modelo do provedor subjacente a ele. O primeiro modelo adicionado a uma conta torna-se seu padrão.

## Referencie o modelo de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo é usado por padrão

Quando `L10N.md` omite `model`,Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar padrão e selecione **Tornar padrão**.

Para um comportamento previsível em vários modelos, referencie explicitamente um handle em `L10N.md`.

Você pode colocar um diferente `model` identificador em um aninhado `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para um único idioma de destino. O Glossia usa a configuração aplicável mais próxima para cada documento e idioma. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução para com um erro. Ele não tenta outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o identificador do modelo. Insira uma nova chave de provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o handle não precisam ser alterados.