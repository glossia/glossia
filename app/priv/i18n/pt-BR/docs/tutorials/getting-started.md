%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório GitHub ao Glossia, escolhe seus primeiros idiomas-alvo e prepara uma base de localização para a sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você possa gerenciar configurações e projetos.
- Um repositório GitHub para o qual você pode conceder ao Glossia GitHub App permissão para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abra **Configurações**, em seguida **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um nome curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte de um nome de provedor ou de modelo para filtrar a lista.
3. Selecione o modelo que deseja que o Glossia use.
4. Digite a chave do provedor e salve o modelo.

O nome curto permite que os repositórios se refiram a este modelo de conta sem colocar credenciais do provedor no controle de versão. Veja [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Iniciar um projeto

Retornar para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao aplicativo Glossia GitHub acesso ao repositório. Após retornar ao Glossia, reabra **Novo projeto** caso necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas repositórios disponíveis através da instalação do GitHub App da conta atual.

Continue para a etapa de idioma.

## 4\. Escolha os idiomas alvo

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração.

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e a atividade recente, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e voltar à visão geral do projeto sem perder o estado da configuração. Se a configuração falhar, o mesmo cartão explica o que precisa de atenção e oferece **Reiniciar configuração**.

## 6\. Revisar o resultado

Quando a configuração for concluída, abra a visão geral do projeto e revise o pull request criado para o repositório. A linha de base proposta normalmente inclui:

- Uma raiz `L10N.md` arquivo com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e mesclhe o pull request pelo seu fluxo normal do GitHub. As futuras execuções de tradução usam o mesclado `L10N.md` contexto.

A visão geral do projeto mantém o pull request de configuração visível até que seja mesclado. Se for fechado sem mesclagem, reabra-o pelo link no aviso de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entenda os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprenda como os modelos de conta funcionam](/docs/explanation/account-models)