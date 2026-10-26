%{
  title: "Configurar um provedor de modelo",
  summary: "Adicionar um modelo de conta e referenciá-lo com segurança a partir de repositórios.",
  category: "Passo a passo",
  section: "translation",
  order: 3
}
---

A configuração do projeto e as execuções de tradução utilizam modelos configurados para a conta atual do Glossia. Configure pelo menos um modelo antes de criar um projeto.

## Adicionar um modelo

1. Abra **Configurações** e selecione **Modelos**.
2. Selecione **Novo modelo**.
3. Digite um identificador único, como `translation-default`.
4. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
5. Selecione um modelo e insira sua chave de provedor.
6. Salve o modelo.

O identificador permanece estável mesmo quando você altera o modelo de provedor posteriormente. O primeiro modelo adicionado a uma conta torna-se seu padrão.

## Referenciar o modelo a partir de um repositório

Defina `model` no frontmatter relevante `L10N.md`:

```yaml
---
model: translation-default
---
```

O repositório armazena apenas o identificador. A chave do provedor permanece nas configurações da conta.

## Escolha qual modelo é usado por padrão

Quando `L10N.md` omite `model`, o Glossia utiliza o modelo padrão da conta. Para alterá-lo, abra o modelo que deve tornar-se o padrão e selecione **Tornar padrão**.

Para comportamento previsível entre vários modelos, referencie um identificador explicitamente em `L10N.md`.

Você pode colocar um identificador `model` diferente em um `L10N.md` aninhado para uma área de conteúdo, ou em `L10N/<locale>.md` para um locale-alvo. O Glossia utiliza a configuração aplicável mais próxima para cada documento e locale. Ele não divide automaticamente o trabalho entre os modelos configurados.

Se um identificador explícito não existe na conta, a tradução para com um erro. Ela não faz fallback para outro modelo.

## Alterar ou rotacionar uma chave de provedor

Abra **Configurações**, selecione **Modelos** e abra o identificador do modelo. Insira uma nova chave de provedor e salve. Deixar o campo da chave em branco mantém a chave atual.

Repositórios que referenciam o identificador não precisam ser alterados.

## Adicionar Jev para decisões de qualidade de tradução

1. Abra **Configurações → Modelos → Novo modelo** e selecione **Decisão** como categoria.
2. Use um identificador como `translation-quality`. Mantenha `typesafe/jev-latest`, ou insira uma versão fixa do modelo TypeSafe Jev.
3. Insira sua chave de provedor TypeSafe. Deixe o endereço base vazio para usar o endpoint nativo TypeSafe; um endereço personalizado deve incluir seu prefixo de versão, como `https://api.typesafe.ai/v1`.
4. Defina a pontuação mínima de qualidade de 1 a 10, em seguida salve. O primeiro modelo de decisão torna-se o modelo padrão de decisão e habilita a avaliação automaticamente.
5. Execute a tradução. Dimensões de qualidade falhas solicitam correção dentro do orçamento `retries` configurado em seu repositório.

Modelos gerativos e de decisão têm padrões separados. Mantenha os identificadores do seu modelo de tradução inalterados. Modelos de decisão não podem ser selecionados pelos identificadores de tradução do repositório ou pelas regras de roteamento de locale. Remova todos os modelos de decisão para desativar a avaliação.
