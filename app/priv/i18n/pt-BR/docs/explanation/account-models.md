%{
  title: "Modelos de conta",
  summary: "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "explicação",
  order: 2
}
---
Glossia separa instruções do repositório das credenciais do provedor de modelo. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com o mesmo provedor. Modelos com escopo de conta permitem que administradores rotem uma chave de provedor ou alternem para outro modelo subjacente uma vez, sem editar cada repositório.

Esta fronteira também mantém credenciais fora do controle de versão. Um repositório contém um identificador legível como `translation-default`, não a chave do provedor.

## Identificadores fornecem intenção estável

O campo `model` no `GLOSSIA.md` refere-se a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo do provedor esse identificador seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são utilizados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de fallback ou um nível de qualidade automática. O autor do repositório escolhe seu propósito através de identificadores estáveis como `translation-default`, `long-form` ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e localização alvo:

1. O arquivo `GLOSSIA/<locale>.md` mais próximo que declara `model` vence para essa localização.
2. Caso contrário, o arquivo `GLOSSIA.md` mais próximo que declara `model` vence para o seu diretório.
3. As configurações dos arquivos `GLOSSIA.md` do pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

O setup do projeto precisa de um modelo antes que o repositório tenha seu próprio `GLOSSIA.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão e um administrador pode definir outro modelo como padrão a partir de sua página de configurações.

Uma vez que o repositório possui `GLOSSIA.md`, usar um identificador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## A fronteira de revisão humana

A saída do modelo é trabalho proposto, não um merge automático. A atividade de setup e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas por meio de um pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.