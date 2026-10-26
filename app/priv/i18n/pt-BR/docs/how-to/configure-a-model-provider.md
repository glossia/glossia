%{
  title: "Configure um provedor de modelo",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "tutorial",
  section: "translation",
  order: 3
}
---

A configuração do projeto e as execuções de tradução usam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Digite um identificador exclusivo, como `translation-default`.
4. Abra o seletor de modelo e digite parte de um provedor ou nome de modelo para filtrar a lista.
5. Selecione um modelo e digite sua chave do provedor.
6. Salve o modelo.

O identificador é estável mesmo quando você altera o modelo de provedor subjacente posteriormente. O primeiro modelo adicionado a uma conta se torna o padrão dela.

## Referenciar o modelo a partir de um repositório

Defina `model` no cabeçalho relevante `L10N.md`:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolher qual modelo é usado por padrão

Quando `L10N.md` omitir `model`, o Glossia usará o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Tornar padrão**.

Para comportamento previsível em vários modelos, referencie explicitamente um identificador em `L10N.md`.

Você pode colocar um identificador `model` diferente em um `L10N.md` aninhado para uma área de conteúdo, ou em `L10N/<locale>.md` para um local de destino. Glossia usa a configuração mais aplicável para cada documento e local. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução para com um erro. Ele não recorre a outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Digite uma nova chave do provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam de alteração.

## Adicionar Jev para decisões de qualidade de tradução

1. Abra **Configurações → Modelos → Novo modelo** e selecione **Decisão** como categoria.
2. Use um identificador, como `translation-quality`. Mantenha `typesafe/jev-latest`, ou insira uma versão fixada do modelo TypeSafe Jev.
3. Digite sua chave do provedor TypeSafe. Deixe o endereço base vazio para usar o endpoint nativo TypeSafe; um endereço personalizado deve incluir seu prefixo de versão, como `https://api.typesafe.ai/v1`.
4. Defina a pontuação mínima de qualidade de 1 a 10, em seguida salve. O primeiro modelo de decisão se torna o modelo de decisão padrão e habilita a avaliação automaticamente.
5. Execute a tradução. Dimensões de qualidade falidas solicitam correção dentro do orçamento `retries` configurado em seu repositório.

Modelos gerativos e de decisão possuem padrões separados. Mantenha os identificadores dos seus modelos de tradução inalterados. Modelos de decisão não podem ser selecionados por identificadores de tradução de repositório ou regras de roteamento de local. Remova todos os modelos de decisão para desabilitar a avaliação.
