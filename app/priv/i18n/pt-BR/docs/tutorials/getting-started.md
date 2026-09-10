%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório do GitHub ao Glossia, seleciona seus primeiros idiomas de destino e prepara uma base de localização para revisão pela sua equipe.

## Antes de começar

Você precisa:

- Uma conta do Glossia na qual você possa gerenciar configurações e projetos.
- Um repositório do GitHub em que você possa conceder permissão ao Glossia GitHub App para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem de grande escala](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abra **Configurações**, então **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um nome curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte de um nome de provedor ou modelo para filtrar a lista.
3. Selecione o modelo que você deseja que o Glossia use.
4. Digite a chave do provedor e salve o modelo.

O nome curto permite que os repositórios se refiram a este modelo de conta sem colocar credenciais do provedor no controle de versão. Veja [Configurar provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Inicie um projeto

Voltar para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e autorize o aplicativo GitHub do Glossia a acessar o repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas repositórios disponíveis através da instalação do GitHub App da conta atual.

Continuar para a etapa de idioma.

## 4\. Escolha os idiomas de destino

Selecione um ou mais idiomas para serem gerados a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso exibe o estado atual e atividades recentes, incluindo a preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar à visão geral do projeto sem perder o estado de configuração. Se a configuração falhar, o mesmo cartão explica o que precisa atenção e oferece **Reiniciar configuração**.

## 6\. Revisar o resultado

Quando a configuração for concluída, abra a visão geral do projeto e revise o pull request criado para o repositório. A base proposta normalmente inclui:

- Uma raiz `L10N.md` arquivo com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou conteúdo necessárias para carregar os arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e realize o merge por meio do fluxo de trabalho normal do GitHub. As execuções futuras de tradução utilizam o mesclado `L10N.md` contexto.

A visão geral do projeto mantém o pull request de configuração visível até que seja mesclado. Se for fechado sem ser mesclado, reabra-o a partir do link no aviso de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entender os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprenda como os modelos de conta funcionam](/docs/explanation/account-models)