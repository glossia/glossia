%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados por handle.",
  category: "Explicação",
  order: 2
}
---
O Glossia separa as instruções do repositório das credenciais do provedor de modelos. Os repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação com o provedor. Modelos de conta permitem que os administradores rotem uma chave do provedor ou mudem o modelo subjacente uma vez sem editar cada repositório.

Essa fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível como `translation-default`, não a chave do provedor.

## Identificadores fornecem intenção estável

O `model` campo em `L10N.md` se refere a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo de provedor esse identificador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são utilizados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de fallback ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de identificadores estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o idioma-alvo:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` prevalece para aquele idioma.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` prevalece para o seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um handle, o Glossia usa o padrão da conta.

Um handle configurado explicitamente deve existir. O Glossia relata um erro para um handle desconhecido em vez de mudar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha o seu próprio `L10N.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode tornar outro modelo padrão na sua página de configurações.

Uma vez que um repositório tem `L10N.md`, usando um identificador explícito deixa a escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite de revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas por meio de um pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já usam para o código.