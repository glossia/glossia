%{
  title: "Configurar um provedor de modelo",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "how-to",
  order: 3
}
---
A configuração do projeto e as execuções de tradução usam os modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Digite um identificador exclusivo, como `translation-default`.
4. Abra o seletor de modelo e digite parte de um nome de provedor ou modelo para filtrar a lista.
5. Selecione um modelo e digite sua chave de provedor.
6. Salve o modelo.

O identificador permanece estável mesmo quando você altera posteriormente o modelo do provedor subjacente. O primeiro modelo adicionado a uma conta torna-se seu padrão.

## Referenciar o modelo a partir de um repositório

Defina `model` no frontmatter do `GLOSSIA.md` relevante:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolher qual modelo é usado como padrão

Quando `GLOSSIA.md` omite `model`, o Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Definir como padrão**.

Para comportamento previsível entre vários modelos, referencie um identificador explicitamente em `GLOSSIA.md`.

Você pode colocar um identificador `model` diferente em um `GLOSSIA.md` aninhado para uma área de conteúdo, ou em `GLOSSIA/<locale>.md` para uma localização-alvo. O Glossia usa a configuração aplicável mais próxima para cada documento e localização. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução termina com um erro. Ele não recorre a outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Digite uma nova chave de provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam mudar.