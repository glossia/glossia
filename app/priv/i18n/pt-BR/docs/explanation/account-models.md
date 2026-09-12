%{
  title: "Modelos de conta",
  summary:
    "Por que provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "explicação",
  order: 2
}
---
Glossia separa instruções de repositório das credenciais do provedor de modelo. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação com o provedor. Modelos vinculados à conta permitem que administradores rotacionem uma chave do provedor ou alterem o modelo subjacente uma única vez sem editar todos os repositórios.

Esta fronteira também mantém as credenciais fora do controle de versão. Um repositório contém uma alça legível, como `translation-default`, não a chave do provedor.

## As alças fornecem intenção estável.

O `model` campo em `L10N.md` se refere ao handle do modelo de conta:

```yaml
model: translation-default
```

O handle expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo do provedor que o handle seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são utilizados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback, ou um nível de qualidade automático. O autor do repositório escolhe seu propósito por meio de handles estáveis tais como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e a localização de destino:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` prevalece para essa localização.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` prevalece para o seu diretório.
3. Pai `L10N.md` As configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um handle, o Glossia usa o padrão da conta.

Um handle configurado explicitamente deve existir. O Glossia relata um erro para um handle desconhecido em vez de alternar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha o seu próprio `L10N.md`. O Glossia seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode tornar outro modelo o padrão na página de suas configurações.

Uma vez que um repositório possui `L10N.md`, ao usar um identificador explícito torna a escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas por meio de um pull request para revisão da equipe. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já usam para código.