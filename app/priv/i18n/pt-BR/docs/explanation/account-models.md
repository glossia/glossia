%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelo são configurados uma vez por conta e referenciados por handle.",
  category: "explicação",
  section: "plataforma",
  order: 2
}
---
Glossia separa instruções de repositório de credenciais do provedor de modelo. Repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com o mesmo relacionamento com o provedor. Modelos com escopo de conta permitem que administradores rodem uma chave de provedor ou alternem o modelo subjacente uma vez sem editar cada repositório.

Esta fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, como um `translation-default`, não a chave do provedor.

## Os identificadores fornecem intenção estável.

O `model` campo em `L10N.md` refere-se a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor aquele identificador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

Glossia usa um único modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de handles estáveis, tais como `translation-default`O documento reassemblado anteriormente falhou na validação: a recuperação do texto-literal do Markdown deve retornar um array de strings JSON de mesmo comprimento. `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o locale de destino:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` prevalece para aquele locale.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` prevalece para o seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de mudar silenciosamente para o padrão da conta.

## Seleção padrão

O projeto precisa definir um modelo antes que o repositório tenha o seu próprio `L10N.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a uma conta se torna o padrão, e um administrador pode tornar outro modelo o padrão através de sua página de configurações.

Assim que um repositório possui `L10N.md`, usando um handle explícito deixa a escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A configuração e a atividade de tradução permanecem visíveis no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e de propriedade que as equipes já usam para o código.