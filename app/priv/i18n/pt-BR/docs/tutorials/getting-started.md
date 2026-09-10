%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório GitHub ao Glossia, escolhe os primeiros idiomas-alvo e prepara uma linha de base de localização para sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você pode gerenciar configurações e projetos.
- Um repositório GitHub no qual você pode conceder permissão ao Glossia GitHub App para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abrir **Configurações**, então **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um identificador curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte de um nome de provedor ou modelo para filtrar a lista.
3. Selecione o modelo que deseja que o Glossia use.
4. Digite a chave do provedor e salve o modelo.

O identificador permite aos repositórios se referirem a este modelo de conta sem inserir credenciais do provedor no controle de versão. Consulte [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Inicie um projeto

Retorne para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao aplicativo GitHub do Glossia o acesso ao repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas os repositórios disponíveis através da instalação da GitHub App da conta atual.

Continue para o passo do idioma.

## 4\. Escolha os idiomas de destino

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso exibe o estado atual e a atividade recente, incluindo a preparação do repositório, a inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e voltar à visão geral do projeto sem perder o estado de configuração. Se a configuração falhar, o mesmo cartão explica o que precisa de atenção e oferece **Retentar a configuração**.

## 6\. Revisar o resultado

Quando a configuração terminou, abra a visão geral do projeto e revise o pull request criado para o repositório. A linha de base proposta normalmente inclui:

- Um arquivo na raiz `L10N.md` arquivo com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e realize o merge do pull request através do seu fluxo normal do GitHub. As execuções futuras de tradução utilizam o mesclado `L10N.md` contexto.

A visão geral do projeto mantém o pull request de configuração visível até que seja mesclado. Se estiver fechado sem ter sido mesclado, reabra-o pelo link no aviso de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entender os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprender como funcionam os modelos de conta](/docs/explanation/account-models)