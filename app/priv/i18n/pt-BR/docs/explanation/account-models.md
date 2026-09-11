%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "Explicação",
  order: 2
}
---
O Glossia separa as instruções do repositório das credenciais do provedor do modelo. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação de provedor. Modelos com escopo de conta permitem aos administradores rotacionar uma chave do provedor ou alternar o modelo subjacente uma vez sem editar cada repositório.

Essa fronteira também mantém credenciais fora do controle de código-fonte. Um repositório contém um identificador legível, como `translation-default`, não a chave do provedor.

## Identificadores fornecem intenção estável

O `model` campo em `L10N.md` refere-se a um handle do modelo de conta:

```yaml
model: translation-default
```

O handle expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor esse handle seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback ou um nível de qualidade automático. O autor do repositório escolhe seu propósito por meio de handles estáveis, como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e a localização de destino:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` vence para essa localização.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` vence para o seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um manipulador, o Glossia usa o padrão da conta.

Um manipulador configurado explicitamente deve existir. O Glossia relata um erro referente a um manipulador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha o seu próprio `L10N.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode tornar outro modelo o padrão a partir de sua página de configurações.

Depois que um repositório tem `L10N.md`, usando um manipulador explícito torna a escolha clara para revisores. Omitir `model` , mantém o repositório no padrão da conta.

## O limite de revisão humana

A saída do modelo é trabalho proposto, não uma fusão automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas por meio de uma pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já utilizam para código.