%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório GitHub ao Glossia, escolhe seus primeiros idiomas-alvo e prepara uma linha de base de localização para sua equipe revisar.

## Antes de começar

Você precisa:

- Uma conta do Glossia onde você pode gerenciar configurações e projetos.
- Um repositório GitHub para o qual você pode conceder permissão ao Glossia GitHub App para ler e atualizar.
- Uma chave de provedor para um suportado [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configure um modelo de conta

Abra **Configurações**, em seguida **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um nome curto, como `translation-default`.
2. Abra o seletor de modelo e digite parte do nome do provedor ou do modelo para filtrar a lista.
3. Selecione o modelo que deseja usar com o Glossia.
4. Insira a chave do provedor e salve o modelo.

O nome curto permite que os repositórios se refiram a este modelo de conta sem colocar as credenciais do provedor no controle de versão. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Iniciar um projeto

Voltar para **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda ao Glossia GitHub App o acesso ao repositório. Após retornar ao Glossia, reabra **Novo projeto** se necessário.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas os repositórios disponíveis através da instalação do GitHub App da conta atual.

Continue para a etapa de idioma.

## 4\. Escolha idiomas de destino

Selecione um ou mais idiomas a serem gerados a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e as atividades recentes, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar ao resumo do projeto sem perder o estado da configuração. Se a configuração falhar, o mesmo cartão explica o que precisa de atenção e oferece **Reiniciar configuração**.

## 6\. Revisar o resultado

Quando a configuração termina, acesse o resumo do projeto e revise o pull request criado para o repositório. A base proposta normalmente inclui:

- A raiz `L10N.md` arquivo com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve que já estava disponível no repositório.

Revise e integre o pull request através do seu fluxo de trabalho normal do GitHub. As futuras execuções de tradução utilizam o mesclado `L10N.md` Contexto.

A visão geral do projeto mantém o pull request de configuração visível até que seja integrado. Caso seja fechado sem integração, reabra-o pelo link no aviso de configuração.

## Próximos passos

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entenda os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprenda como os modelos de conta funcionam](/docs/explanation/account-models)