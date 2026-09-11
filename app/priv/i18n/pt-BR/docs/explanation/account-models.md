%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "explicação",
  order: 2
}
---
Glossia separa as instruções do repositório das credenciais do provedor de modelos. Repositórios descrevem o que deve ser traduzido, enquanto contos decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação com o provedor. Modelos de escopo de conta permitem que administradores rotem uma chave de provedor ou troquem o modelo subjacente uma vez sem editar todos os repositórios.

Essa fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, como `translation-default`, e não a chave do provedor.

## Identificadores fornecem intenção estável

O campo `model` em `L10N.md` refere-se a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode depois atualizar qual modelo de provedor aquele identificador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback ou uma camada de qualidade automática. O autor do repositório escolhe seu propósito através de identificadores estáveis, como `translation-default`, `long-form` ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o local de destino:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para aquele local.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. As configurações dos pais `L10N.md` são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de mudar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que o repositório tenha seu próprio `L10N.md`. O Glossia seleciona, portanto, o padrão da conta. O primeiro modelo adicionado à conta torna-se o padrão, e um administrador pode tornar outro modelo o padrão a partir de sua página de configurações.

Depois que o repositório possui `L10N.md`, usar um identificador explícito torna sua escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## A fronteira de revisão humana

A saída do modelo é trabalho proposto, não uma fusão automática. A atividade de setup e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.