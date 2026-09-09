%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "explicação",
  order: 2
}
---
A Glossia separa as instruções do repositório das credenciais do provedor de modelo. Os repositórios descrevem o que deve ser traduzido, enquanto as contas decidem quais [modelo de linguagem de grande escala](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação de provedor. Modelos escopados por conta permitem que administradores rotacionem uma chave de provedor ou alternem o modelo subjacente uma única vez sem editar cada repositório.

Essa fronteira também mantém credenciais fora do controle de versão. Um repositório contém um identificador legível como `translation-default`, não a chave do provedor.

## Os identificadores fornecem uma intenção estável.

O `model` campo em `L10N.md` refere-se a um identificador do modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor esse identificador seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

Glossia utiliza um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback, ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de handles estáveis, como `translation-default`O documento remontado anteriormente falhou na validação: a recuperação de nó de texto Markdown produziu uma tradução vazia `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o locale de destino:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` vence para esse locale.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` vence para seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia exibe um erro para um identificador desconhecido em vez de alternar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que o repositório tenha o seu próprio `L10N.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode definir outro modelo como padrão na sua página de configurações.

Uma vez que um repositório tem `L10N.md`, ao usar um identificador explícito, deixa a escolha clara para os revisores. Omitindo `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para que a equipe revise. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já utilizam para código.