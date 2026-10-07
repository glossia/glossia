%{
  title: "Configure um provedor de modelo",
  summary: "Adicione um modelo de conta e referencie-o com segurança nos repositórios.",
  category: "Tutorial",
  section: "translation",
  order: 3
}
---
A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abrir **Configurações** e selecionar **Modelos**.
2. Selecionar **Novo modelo**.
3. Digite uma alça exclusiva, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome do provedor ou modelo para filtrar a lista.
5. Selecione um modelo e insira a chave do provedor.
6. Salve o modelo.

A alça é estável mesmo quando você altera posteriormente o modelo do provedor por trás dela. O primeiro modelo adicionado à conta torna-se o padrão.

## Referenciar o modelo a partir de um repositório

Definir `model` no relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o handle. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo é usado por padrão

Quando `L10N.md` omitir `model`\`, Glossia usa o modelo padrão da conta. Para alterá-lo, abra o modelo que deve se tornar o padrão e selecione **Tornar padrão**.

Para comportamento previsível em vários modelos, refira-se explicitamente a um handle em `L10N.md`.

Você pode colocar um diferente `model` handle em um aninhado `L10N.md` para uma área de conteúdo, ou em `L10N/<locale>.md` para um único idioma de destino. O Glossia utiliza a configuração mais aplicável para cada documento e idioma. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existir na conta, a tradução é interrompida com um erro. Ela não recorre a outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abrir **Configurações**, selecione **Modelos**, e abra o identificador do modelo. Digite uma nova chave de provedor e salve. Deixar o campo de chave em branco mantém a chave atual.

Repositórios que referenciam o handle não precisam mudar.

## Adicionar Jev para decisões de qualidade de tradução

1. Abrir **Configurações → Modelos → Novo modelo** e selecione **Decisão** como a categoria.
2. Use um handle como `translation-quality`. Mantenha `typesafe/jev-latest`, ou digite uma versão fixada do modelo Jev TypeSafe.
3. Digite sua chave de provedor TypeSafe. Deixe o endereço base vazio para usar o endpoint TypeSafe nativo; um endereço personalizado deve incluir seu prefixo de versão, como `https://api.typesafe.ai/v1`.
4. Defina a pontuação de qualidade mínima de 1 a 10, em seguida salve. O primeiro modelo de decisão torna-se o modelo de decisão padrão e habilita a avaliação automaticamente.
5. Execute a tradução. As dimensões de qualidade falhadas requerem correção dentro do `retries` orçamento configurado em seu repositório.

Modelos gerativos e de decisão têm padrões separados. Mantenha os handles do modelo de tradução sem alterações. Os modelos de decisão não podem ser selecionados por handles de tradução de repositório ou regras de roteamento de localidade. Remova todos os modelos de decisão para desabilitar a avaliação.