%{
  title: "Configure um provedor de modelo",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir dos repositórios.",
  category: "Tutorial",
  order: 3
}
---
A configuração do projeto e as execuções de tradução usam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecione **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome de um provedor ou do modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salve o modelo.

O identificador permanece estável mesmo quando você posteriormente altera o modelo do provedor subjacente. O primeiro modelo adicionado a uma conta torna-se seu padrão.

## Referenciar o modelo a partir de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo será usado por padrão

Quando `L10N.md` omite `model`, O Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Tornar padrão**.

, Para comportamento previsível entre vários modelos, referencie explicitamente um handle em `L10N.md`.

Você pode colocar um diferente `model` handle em um aninhado `L10N.md` , para uma área de conteúdo, ou em `L10N/<locale>.md` para uma única localidade de destino. O Glossia usa a configuração mais próxima aplicável para cada documento e localidade. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução para com um erro. Ela não recorre a outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o identificador do modelo. Insira uma nova chave de provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam ser alterados.