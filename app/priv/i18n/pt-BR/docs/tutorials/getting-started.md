%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---

Este tutorial conecta um repositório do GitHub ao Glossia, escolhe os primeiros idiomas-alvo e prepara uma base de localização para sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você possa gerenciar configurações e projetos.
- Um repositório do GitHub no qual você pode conceder permissão à App do GitHub do Glossia para ler e atualizar.
- Uma chave de provedor para um [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) suportado.

## 1. Configure um modelo de conta

Abra **Configurações**, depois **Modelos** e selecione **Novo modelo**.

1. Dê ao modelo um código curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte do nome do provedor ou do modelo para filtrar a lista.
3. Selecione o modelo que você deseja que o Glossia utilize.
4. Insira a chave de provedor e salve o modelo.

O código curto permite que os repositórios se referam a este modelo de conta sem incluir credenciais de provedor no controle de versão. Consulte [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2. Iniciar um projeto

Volte para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda acesso do App do GitHub do Glossia ao repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3. Escolher um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas os repositórios disponíveis através da instalação do App do GitHub da conta atual.

## 4. Escolher como configurar o projeto

Selecione **Configuração automatizada** para permitir que o Glossia inspecione o repositório e proponha a configuração de localização em um pull request. Este tutorial segue esse caminho.

Se o repositório já tiver um arquivo `L10N.md` ou se preferir escrevê-lo você mesmo, selecione **Configuração manual** ao invés. O Glossia cria o projeto imediatamente e você pode pular os passos restantes. Consulte [Configuração do projeto](/docs/reference/project-setup) para o que cada modo faz.

## 5. Escolher idiomas-alvo

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório e inicie a configuração.

## 6. Acompanhar o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e a atividade recente, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar ao resumo do projeto sem perder o estado da configuração. Se a configuração falhar, leia a notificação de falha. O Glossia descarta o projeto provisório; corrija o pré-requisito e inicie novamente através de **Novo projeto**. Veja [Retentar a configuração do projeto](/docs/how-to/retry-project-setup).

## 7. Revisar o resultado

Quando a configuração terminar, abra o resumo do projeto e revise o pull request criado para o repositório. A base proposta normalmente inclui:

- Um arquivo `L10N.md` raiz com idioma de origem, caminhos de origem e idiomas-alvo.
- As alterações de aplicação ou conteúdo mínimas necessárias para carregar os arquivos localizados.
- Qualquer validação leve que já estivesse disponível no repositório.

Revise e funde o pull request através do seu fluxo de trabalho normal do GitHub. As execuções futuras de tradução usam o contexto `L10N.md` fundido.

O resumo do projeto mantém o pull request de configuração visível até que seja fundido. Se for fechado sem ser fundido, reabra-o a partir do link no aviso de configuração.

## Próximos passos

- [Adicionar uma nova linguagem](/docs/how-to/add-a-new-language)
- [Entender os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprender como os modelos de conta funcionam](/docs/explanation/account-models)
