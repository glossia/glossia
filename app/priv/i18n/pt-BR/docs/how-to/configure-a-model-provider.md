%{
  title: "Configurar um provedor de modelos",
  summary: "Adicione um modelo de conta e referencie-o com segurança nos repositórios.",
  category: "how-to",
  order: 3
}
---
A configuração do projeto e as execuções de tradução usam modelos configurados para a conta atual da Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Insira um identificador exclusivo, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
5. Selecione um modelo e insira a chave do provedor.
6. Salve o modelo.

O identificador permanece estável mesmo que você altere posteriormente o modelo do provedor associado a ele. O primeiro modelo adicionado a uma conta se torna o modelo padrão.

## Referenciar o modelo em um repositório

Defina `model` no front matter relevante de `GLOSSIA.md`:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolher qual modelo será usado por padrão

Quando `GLOSSIA.md` omite `model`, a Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Definir como padrão**.

Para obter um comportamento previsível ao usar vários modelos, referencie explicitamente um identificador em `GLOSSIA.md`.

Você pode inserir um identificador `model` diferente em um `GLOSSIA.md` aninhado para uma área de conteúdo específica ou em `GLOSSIA/<locale>.md` para uma localidade de destino específica. A Glossia usa a configuração aplicável mais próxima para cada documento e localidade. Ela não distribui automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução será interrompida com um erro. A Glossia não usará outro modelo como alternativa.

## Alterar ou substituir uma chave de provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Insira uma nova chave de provedor e salve. Se o campo da chave permanecer em branco, a chave atual será mantida.

Os repositórios que referenciam o identificador não precisam ser alterados.