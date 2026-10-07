%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório GitHub ao Glossia, seleciona os primeiros idiomas-alvo e prepara uma base de localização para sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você pode gerenciar configurações e projetos.
- Um repositório GitHub para o qual você pode conceder permissão à GitHub App do Glossia para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abra **Configurações**, em seguida **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um identificador curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
3. Selecione o modelo que você deseja que o Glossia use.
4. Digite a chave do provedor e salve o modelo.

Este identificador permite que repositórios se referam a este modelo de conta sem armazenar as credenciais do provedor no controle de versão. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Começar um projeto

Retornar a **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao aplicativo do Glossia GitHub o acesso ao repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas repositórios disponíveis através da instalação do GitHub App da conta atual.

## 4\. Escolha como configurar o projeto

Selecione **Configuração automatizada** para permitir que o Glossia inspecione o repositório e proponha a configuração de localização em um pull request. Este tutorial segue esse caminho.

Se o repositório já possui um `L10N.md` arquivo, ou prefere escrevê-lo você mesmo, selecione **Configuração manual** Em vez disso. Glossia cria o projeto imediatamente e você pode pular os passos restantes. Veja [Configuração do projeto](/docs/reference/project-setup) para saber o que cada modo faz.

## 5\. Escolha os idiomas de destino

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 6\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e as atividades recentes, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar à visão geral do projeto sem perder o estado de configuração. Se a configuração falhar, leia o aviso de falha. O Glossia descarta o projeto provisório; corrija o pré-requisito e inicie novamente através de **Novo projeto**. Veja [Retentar a configuração do projeto](/docs/how-to/retry-project-setup).

## 7\. Revisar o resultado

Quando a configuração for concluída, abra a visão geral do projeto e revise o pull request criado para o repositório. A base proposta normalmente inclui:

- Uma raiz `L10N.md` um arquivo com língua de origem, caminhos de origem e línguas alvo.
- As menores alterações de aplicativo ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e fundir a solicitação de pull através do seu fluxo de trabalho padrão do GitHub. As futuras execuções de tradução usam o fundido `L10N.md` contexto.

O resumo do projeto mantém a solicitação de pull de configuração visível até que seja fundida. Se estiver fechada sem ter sido fundida, reabra-a a partir do link na notificação de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entenda os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprenda como funcionam os modelos de conta](/docs/explanation/account-models)