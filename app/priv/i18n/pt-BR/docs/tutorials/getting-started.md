%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---

Este tutorial conecta um repositório do GitHub ao Glossia, escolhendo seus primeiros idiomas-alvo e preparando uma base de localização para sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você possa gerenciar configurações e projetos.
- Um repositório do GitHub ao qual você possa conceder permissão de leitura e atualização à Glossia GitHub App.
- Uma chave do provedor para um [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) suportado.

## 1. Configure um modelo de conta

Abra **Configurações**, em seguida **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um nome curto, por exemplo `translation-default`.
2. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
3. Selecione o modelo que você deseja que o Glossia use.
4. Insira a chave do provedor e salve o modelo.

O nome curto permite que os repositórios se referenciem a este modelo de conta sem colocar credenciais do provedor no controle de versão. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2. Inicie um projeto

Volte para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda acesso ao repositório à Glossia GitHub App. Após retornar ao Glossia, abra novamente **Novo projeto** se necessário.

## 3. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas repositórios disponíveis por meio da instalação do GitHub App da conta atual.

## 4. Escolha como configurar o projeto

Selecione **Configuração automática** para permitir que o Glossia inspecione o repositório e proponha a configuração de localização em uma solicitação pull. Este tutorial segue esse caminho.

Se o repositório já contém o arquivo `L10N.md` ou se você preferir escrever-lo você mesmo, selecione **Configuração manual** em vez disso. O Glossia cria o projeto imediatamente e você pode ignorar os passos restantes. Veja [Configuração do projeto](/docs/reference/project-setup) para o que cada modo faz.

## 5. Escolha idiomas-alvo

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório, em seguida inicie a configuração.

## 6. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e a atividade recente, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar ao resumo do projeto sem perder o estado de configuração. Se a configuração falhar, leia o aviso de falha. O Glossia descarta o projeto provisório; corrija o pré-requisito e inicie novamente através de **Novo projeto**. Veja [Tentar novamente a configuração do projeto](/docs/how-to/retry-project-setup).

## 7. Revise o resultado

Quando a configuração terminar, abra o resumo do projeto e revise a solicitação pull criada para o repositório. A base proposta normalmente inclui:

- Um arquivo de raiz `L10N.md` com idioma de origem, caminhos de origem e idiomas-alvo.
- As menores alterações de aplicativo ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e mesclando a solicitação pull através do seu fluxo de trabalho normal do GitHub. Execuções futuras de tradução usam o contexto `L10N.md` mesclado.

O resumo do projeto mantém a solicitação pull de configuração visível até que seja mesclada. Se ela for fechada sem ser mesclada, reabra-a pelo link no aviso de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entender os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprender como os modelos de conta funcionam](/docs/explanation/account-models)
