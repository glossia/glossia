%{
  title: "Configure um provedor de modelos",
  summary: "Adicione um modelo de conta e referencie-o com segurança a partir de repositórios.",
  category: "passo a passo",
  section: "translation",
  order: 3
}
---

A configuração do projeto e as execuções de tradução usam modelos configurados na conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Digite um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salve o modelo.

O identificador é estável mesmo que você altere posteriormente o modelo do provedor subjacente. O primeiro modelo adicionado a uma conta se torna seu padrão.

## Referenciar um modelo em um repositório

Defina `model` no frontmatter `L10N.md` relevante:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolher qual modelo é usado por padrão

Quando `L10N.md` omitir `model`, o Glossia usa o modelo padrão da conta. Para alterar isso, abra o modelo que deve se tornar o padrão e selecione **Tornar padrão**.

Para um comportamento previsível entre vários modelos, referencie um identificador explicitamente em `L10N.md`.

Você pode colocar um identificador `model` diferente em um `L10N.md` aninhado para uma área de conteúdo específica, ou em `L10N/<locale>.md` para um locale alvo específico. O Glossia usa a configuração mais aplicável para cada documento e locale. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução para com erro. Não cai de volta para outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Insira uma nova chave de provedor e salve. Deixar o campo chave vazio mantém a chave atual.

Os repositórios que referenciam o identificador não precisam de alteração.

## Adicionar Jev para decisões de qualidade de tradução

1. Abra **Configurações → Modelos → Novo modelo** e selecione **Decisão** como categoria.
2. Use um identificador como `translation-quality`. Mantenha `typesafe/jev-latest`, ou insira uma versão fixa do modelo TypeSafe Jev.
3. Insira sua chave de provedor TypeSafe. Deixe o endereço base vazio para usar o endpoint nativo TypeSafe; um endereço personalizado deve incluir seu prefixo de versão, como `https://api.typesafe.ai/v1`.
4. Defina a pontuação mínima de qualidade de 1 a 10, em seguida, salve. O primeiro modelo de decisão se torna o modelo de decisão padrão e habilita a avaliação automaticamente.
5. Execute a tradução. Dimensões de qualidade falhadas solicitam correção dentro do orçamento `retries` configurado em seu repositório.

Modelos gerativos e de decisão têm padrões separados. Mantenha os identificadores do modelo de tradução inalterados. Modelos de decisão não podem ser selecionados por identificadores de tradução de repositório ou regras de roteamento de locale. Remova todos os modelos de decisão para desabilitar a avaliação.
