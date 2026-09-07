%{
  title: "Configure um provedor de modelos",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "tutorial",
  order: 3
}
---
A configuração do projeto e as execuções de tradução usam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Insira um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave do provedor.
6. Salve o modelo.

O identificador permanece estável mesmo que você altere posteriormente o modelo do provedor por trás dele. O primeiro modelo adicionado à conta torna-se o padrão.

## Referencie o modelo a partir de um repositório

Defina `model` no frontmatter do `GLOSSIA.md` relevante:

```yaml
---
model: translation-default
---
```

O repositório guarda apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo será usado por padrão

Quando `GLOSSIA.md` omite `model`, o Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Tornar padrão**.

Para comportamento previsível entre vários modelos, referencie um identificador explicitamente em `GLOSSIA.md`.

Você pode colocar um identificador `model` diferente em um `GLOSSIA.md` aninhado para uma área de conteúdo, ou em `GLOSSIA/<locale>.md` para um locale de destino. O Glossia usa a configuração mais próxima aplicável para cada documento e locale. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução encerra com um erro. Não há retorno automático para outro modelo.

## Alterar ou rotacionar uma chave do provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Digite uma nova chave do provedor e salve. Deixar o campo de chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam de alteração.