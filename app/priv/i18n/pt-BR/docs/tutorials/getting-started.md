%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "tutorials",
  order: 1
}
---
Este tutorial conecta um repositório do GitHub à Glossia, seleciona os primeiros idiomas de destino e prepara uma base de localização para a revisão da sua equipe.

## Antes de começar

Você precisa de:

- Uma conta da Glossia na qual possa gerenciar configurações e projetos.
- Um repositório do GitHub para o qual possa conceder ao Glossia GitHub App permissão de leitura e atualização.
- Uma chave de provedor para um [modelo de linguagem de grande porte](https://en.wikipedia.org/wiki/Large_language_model) compatível.

## 1. Configure um modelo da conta

Abra **Configurações**, depois **Modelos**, e selecione **Novo modelo**.

1. Atribua ao modelo um identificador curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
3. Selecione o modelo que deseja que a Glossia utilize.
4. Insira a chave do provedor e salve o modelo.

O identificador permite que os repositórios façam referência a esse modelo da conta sem armazenar credenciais do provedor no controle de versão. Consulte [Configurar um provedor de modelos](/docs/how-to/configure-a-model-provider) para obter mais detalhes.

## 2. Inicie um projeto

Volte para **Projetos** e selecione **Novo projeto**.

Se a Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao Glossia GitHub App acesso ao repositório. Depois de retornar à Glossia, abra **Novo projeto** novamente, se necessário.

## 3. Escolha um repositório

Selecione o repositório que deseja localizar. A Glossia lista apenas os repositórios disponíveis por meio da instalação do GitHub App da conta atual.

Prossiga para a etapa de idiomas.

## 4. Escolha os idiomas de destino

Selecione um ou mais idiomas que devem ser gerados a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto a Glossia prepara o projeto. O cartão de progresso exibe o estado atual e as atividades recentes, incluindo a preparação do repositório, a inspeção de arquivos, as alterações, as verificações e a conclusão.

Você pode sair da página e retornar à visão geral do projeto sem perder o estado da configuração. Se a configuração falhar, o mesmo cartão explicará o que requer atenção e oferecerá a opção **Tentar configurar novamente**.

## 6. Revise o resultado

Quando a configuração for concluída, abra a visão geral do projeto e revise a solicitação de pull criada para o repositório. Normalmente, a base proposta inclui:

- Um arquivo `GLOSSIA.md` na raiz, com o idioma de origem, os caminhos de origem e os idiomas de destino.
- As alterações mínimas necessárias no aplicativo ou no conteúdo para carregar os arquivos localizados.
- Todas as validações simples que já estavam disponíveis no repositório.

Revise e integre a solicitação de pull usando o fluxo de trabalho habitual da sua equipe no GitHub. As futuras execuções de tradução utilizarão o contexto de `GLOSSIA.md` integrado.

A visão geral do projeto mantém a solicitação de pull da configuração visível até que ela seja integrada. Se ela for encerrada sem integração, reabra-a pelo link no aviso de configuração.

## Próximas etapas

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Compreender os estados de configuração do projeto](/docs/reference/project-setup)
- [Saiba como funcionam os modelos da conta](/docs/explanation/account-models)