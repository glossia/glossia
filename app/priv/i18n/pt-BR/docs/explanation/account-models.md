%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo identificador.",
  category: "explicação",
  order: 2
}
---
Glossia separa instruções do repositório das credenciais do provedor do modelo. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem a contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação de provedor. Modelos de escopo de conta permitem que administradores rotem uma chave de provedor ou alternem o modelo subjacente uma vez sem editar todos os repositórios.

Essa separação também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, como `translation-default`, não a chave do provedor.

## Identificadores fornecem intenção estável

O campo `model` em `GLOSSIA.md` refere-se a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo do provedor esse identificador seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de reserva, ou um nível automático de qualidade. O autor do repositório escolhe seu propósito através de identificadores estáveis como `translation-default`, `long-form` ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e localidade de destino:

1. O arquivo `GLOSSIA/<locale>.md` mais próximo que declara `model` predomina para essa localidade.
2. Caso contrário, o arquivo `GLOSSIA.md` mais próximo que declara `model` predomina para seu diretório.
3. As configurações do `GLOSSIA.md` pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de alternar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto requer um modelo antes que um repositório tenha seu próprio `GLOSSIA.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão e um administrador pode tornar outro modelo o padrão a partir de sua página de configurações.

Assim que um repositório tem `GLOSSIA.md`, usando um identificador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já usam para código.