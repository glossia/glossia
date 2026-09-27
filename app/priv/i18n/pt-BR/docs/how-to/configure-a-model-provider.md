%{
  title: "Configure um provedor de modelos",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "Tutorial",
  section: "Tradução",
  order: 3
}
---
A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite um handle exclusivo, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
5. Selecione o modelo e insira sua chave do provedor.
6. Salvar o modelo.

O handle é estável mesmo que você altere o modelo do provedor por trás dele mais tarde. O primeiro modelo adicionado a uma conta se torna o padrão.

## Referencie o modelo de um repositório

Defina `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo será usado por padrão

Quando `L10N.md` omite `model`Fluta utiliza o modelo padrão da conta. Para alterar, abra o modelo que deverá se tornar o padrão e selecione **Definir como padrão**.

Para comportamento previsível entre vários modelos, referencie explicitamente um handle em `L10N.md`.

Você pode colocar um `model` handle em `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para um único locale de destino. O Glossia utiliza a configuração aplicável mais próxima para cada documento e locale. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um manipulador explícito não existir na conta, a tradução é interrompida com um erro. Ela não retorna para outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o manipulador do modelo. Insira uma nova chave de provedor e salve. Deixar o campo de chave em branco mantém a chave atual.

Repositórios que referenciam o handle não precisam ser alterados.