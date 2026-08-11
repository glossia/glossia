%{
  title: "Modelos da conta",
  summary: "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo identificador.",
  category: "explanation",
  order: 2
}
---
A Glossia separa as instruções do repositório das credenciais do provedor de modelos. Os repositórios descrevem o que deve ser traduzido, enquanto as contas determinam qual [modelo de linguagem de grande porte](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com o mesmo provedor. Modelos no escopo da conta permitem que administradores alternem uma chave de provedor ou substituam o modelo subjacente uma única vez, sem editar todos os repositórios.

Essa separação também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, como `translation-default`, e não a chave do provedor.

## Os identificadores preservam uma intenção estável

O campo `model` em `GLOSSIA.md` faz referência ao identificador de um modelo da conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Posteriormente, um administrador pode atualizar qual modelo do provedor esse identificador seleciona, mantendo estável a configuração do repositório.

## Como vários modelos são usados

A Glossia usa um modelo configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto de modelos, uma cadeia de contingência nem um nível automático de qualidade. O autor do repositório determina a finalidade de cada modelo por meio de identificadores estáveis, como `translation-default`, `long-form` ou `japanese-specialist`.

A seleção segue a hierarquia de contexto do documento e da localidade de destino:

1. O arquivo `GLOSSIA/<locale>.md` mais próximo que declara `model` prevalece para essa localidade.
2. Caso contrário, o arquivo `GLOSSIA.md` mais próximo que declara `model` prevalece para seu diretório.
3. As configurações de `GLOSSIA.md` do diretório pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, a Glossia usa o modelo padrão da conta.

Um identificador configurado explicitamente deve existir. A Glossia informa um erro para um identificador desconhecido, em vez de alternar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto requer um modelo antes que o repositório tenha seu próprio `GLOSSIA.md`. Portanto, a Glossia seleciona o padrão da conta. O primeiro modelo adicionado a uma conta torna-se o padrão, e um administrador pode definir outro modelo como padrão na página de configurações desse modelo.

Depois que um repositório possui `GLOSSIA.md`, o uso de um identificador explícito deixa a escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## O limite da revisão humana

O resultado do modelo é uma proposta de alteração, não uma integração automática. As atividades de configuração e tradução permanecem visíveis na Glossia, enquanto as alterações do repositório são publicadas por meio de uma solicitação de pull para revisão pela equipe. Isso preserva o mesmo limite de qualidade e responsabilidade que as equipes já aplicam ao código.