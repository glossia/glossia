%{
  title: "Primeiros passos",
  summary: "Conecte um repositório e prepare sua primeira configuração de localização.",
  category: "Tutoriais",
  order: 1
}
---
Este tutorial conecta um repositório do GitHub ao Glossia, escolhe seus primeiros idiomas de destino e prepara uma linha de base de localizações para sua equipe revisar.

## Antes de começar

Você precisa de:

- Uma conta Glossia onde você possa gerenciar configurações e projetos.
- Um repositório do GitHub para o qual você possa permitir que o App do GitHub do Glossia leia e atualize.
- Uma chave de provedor para um [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) suportado.

## 1\. Configure um modelo de conta

Abra **Configurações**, depois **Modelos**, e selecione **Novo modelo**.

1. Dê ao modelo um identificador curto, como `translation-default`.
2. Abra o seletor de modelos e digite parte de um nome de provedor ou modelo para filtrar a lista.
3. Selecione o modelo que deseja que o Glossia use.
4. Insira a chave do provedor e salve o modelo.

O identificador permite que repositórios se refiram a este modelo de conta sem colocar credenciais do provedor no controle de versão. Consulte [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider) para mais detalhes.

## 2\. Inicie um projeto

Retorne a **Projetos** e selecione **Novo projeto**.

Se o Glossia solicitar acesso ao repositório, siga o link para o GitHub e conceda o acesso do App do GitHub do Glossia ao repositório. Caso necessário, após retornar ao Glossia, abra **Novo projeto** novamente.

## 3\. Escolha um repositório

Selecione o repositório que deseja localizar. O Glossia lista apenas os repositórios disponíveis por meio da instalação do App do GitHub da conta atual.

Continue para a etapa de idioma.

## 4\. Escolha os idiomas de destino

Selecione um ou mais idiomas que devem ser produzidos a partir do conteúdo de origem do repositório e, em seguida, inicie a configuração.

## 5\. Acompanhe o progresso da configuração

Mantenha a página de configuração aberta enquanto o Glossia prepara o projeto. O cartão de progresso mostra o estado atual e suas atividades recentes, incluindo preparação do repositório, inspeção de arquivos, alterações, verificações e conclusão.

Você pode sair da página e retornar ao resumo do projeto sem perder o estado da configuração. Caso a configuração falhe, o mesmo cartão explique o que precisa de atenção e oferece **Reiniciar configuração**.

## 6\. Revise o resultado

Quando a configuração estiver concluída, abra o resumo do projeto e revise o pull request criado para o repositório. A linha de base proposta normalmente inclui:

- Um arquivo `GLOSSIA.md` raiz com idioma de origem, caminhos de origem e idiomas de destino.
- As menores alterações de aplicação ou conteúdo necessárias para carregar arquivos localizados.
- Qualquer validação leve já disponível no repositório.

Revise e consolide o pull request por meio do seu fluxo de trabalho normal do GitHub. As execuções futuras de tradução usam o contexto do `GLOSSIA.md` consolidado.

O resumo do projeto mantém o pull request de configuração visível até que seja consolidado. Se este for fechado sem ser consolidado, abra-o a partir do link no aviso de configuração.

## Próximas etapas

- [Adicionar um novo idioma](/docs/how-to/add-a-new-language)
- [Entender os estados de configuração do projeto](/docs/reference/project-setup)
- [Aprender como os modelos de conta funcionam](/docs/explanation/account-models)