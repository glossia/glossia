%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório GitHub ao Glossia, seleciona seus primeiros idiomas-alvo e prepara uma base de localização para sua equipe revisar.

## Antes de começar

O que você precisa:

- Uma conta do Glossia onde você pode gerenciar configurações e projetos.
- Um repositório GitHub onde você pode conceder permissão ao Glossia GitHub App para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abra **Configurações**, então **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um nome curto, por exemplo `translation-default`.
2. Abra o seletor de modelos e digite parte do nome de um provedor ou modelo para filtrar a lista.
3. Selecione o modelo que você deseja que o Glossia utilize.
4. Digite a chave do provedor e salve o modelo.

O identificador permite que os repositórios façam referência a este modelo de conta sem colocar credenciais do provedor no controle de versão. Veja [Configurar provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Iniciar um projeto

Voltar para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao Glossia GitHub App acesso ao repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia apresenta apenas repositórios disponíveis por meio da instalação do aplicativo GitHub da conta atual.

Continue para o passo de idioma.

## 4\. Escolha os idiomas de destino

Selecione um ou mais idiomas que devem ser gerados a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso exibe o estado atual e as atividades recentes, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar à visão geral do projeto sem perder o estado da configuração. Se a configuração falhar, o mesmo cartão explica o que precisa de atenção e oferece **Retentar a configuração**,

## 6\. Verificar o resultado

Quando a configuração termina, abra a visão geral do projeto e revise o pull request criado para o repositório. A base proposta normalmente inclui:

- A raiz `L10N.md` arquivo com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou de conteúdo necessárias para carregar os arquivos localizados.
- Qualquer validação leve já disponível no repositório.

Revise e mesclhe o pull request através do seu fluxo de trabalho normal do GitHub. As execuções futuras de tradução usam o mesclado `L10N.md` contexto.

A visão geral do projeto mantém o pull request de configuração visível até que seja mesclado. Se for fechado sem ser mesclado, reabra-o pelo link no aviso de configuração.

## Próximas etapas

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entenda os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprenda como os modelos de conta funcionam](/docs/explanation/account-models)