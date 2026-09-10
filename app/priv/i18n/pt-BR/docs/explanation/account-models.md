%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados por handle.",
  category: "explicação",
  order: 2
}
---
Glossia separa as instruções do repositório das credenciais do provedor de modelos. Repositórios descrevem o que deve ser traduzido, enquanto as contas definem qual [modelo de linguagem de grande escala](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação com o provedor. Modelos vinculados à conta permitem que administradores rotacionem uma chave do provedor ou alterem o modelo subjacente uma vez sem editar cada repositório.

Essa fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível como `translation-default`, e não a chave do provedor.

## Identificadores fornecem intenção estável

O `model` campo em `L10N.md` refere-se a um identificador do modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor esse identificador seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são utilizados

O Glossia utiliza um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback, ou um nível de qualidade automático. O autor do repositório escolhe seu propósito por meio de identificadores estáveis, como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto do documento e da localização-alvo:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` prevalece para essa localização.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` prevalece para seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um handle, o Glossia usa o padrão da conta.

Um handle configurado explicitamente deve existir. O Glossia relata um erro para um handle desconhecido em vez de mudar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha o seu próprio `L10N.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode tornar outro modelo o padrão na página de configurações.

Uma vez que um repositório tem `L10N.md`, ao usar um identificador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma fusão automática. A configuração e a atividade de tradução permanecem visíveis no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para revisão pela equipe. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já utilizam para o código.