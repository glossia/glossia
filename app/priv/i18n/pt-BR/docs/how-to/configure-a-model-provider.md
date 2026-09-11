%{
  title: "Configurar um provedor de modelo",
  summary: "Adicionar um modelo de conta e referenciá-lo com segurança em repositórios.",
  category: "Tutorial",
  order: 3
}
---
A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual da Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite um handle único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salve o modelo.

O handle permanece estável mesmo quando você altera posteriormente o modelo do provedor por trás dele. O primeiro modelo adicionado a uma conta se torna seu padrão.

## Referenciar o modelo de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo é usado por padrão

Quando `L10N.md` omite `model`, Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Definir como padrão**.

, Para comportamento previsível entre vários modelos, referencie um handle explicitamente em `L10N.md`.

, Você pode colocar um diferente `model` handle em uma aninhada `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para uma única local de destino. O Glossia utiliza a configuração mais aplicável para cada documento e localidade. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um handle explícito não existir na conta, a tradução termina com um erro. Ela não recorre a outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o handle do modelo. Insira uma nova chave de provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o handle não precisam ser alterados.