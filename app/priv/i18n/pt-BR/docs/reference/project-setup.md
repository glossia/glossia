%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  section: "translation",
  order: 2
}
---

A configuração do projeto prepara um repositório conectado para o Glossia. Após o usuário selecionar um repositório no fluxo **Novo projeto**, ele escolhe um dos dois modos de configuração.

## Modos de configuração

| Modo | O que o Glossia faz | Quando escolher |
|---|---|---|
| **Configuração automatizada** | Inspeciona o repositório e abre uma solicitação pull request com a `L10N.md` configuração gerada para as línguas-alvo selecionadas. | O repositório ainda não tem nenhuma configuração de localização. |
| **Configuração manual** | Cria o projeto imediatamente. Ele não inspeciona o repositório, altera-o ou abre uma solicitação pull request. | O repositório já possui um `L10N.md` arquivo, ou um mantenedor o escreverá. |

Os estados, informações de progresso e solicitação pull request descritos abaixo aplicam-se apenas à configuração automatizada.

## Configuração manual

Um projeto configurado manualmente não tem estado de configuração. Ele é utilizável tão logo seja criado e nunca é descartado por uma configuração falha.

O Glossia inicia uma execução de tradução na próxima push para a branch padrão do repositório. A execução traduz para cada alvo declarado nos arquivos [`L10N.md`](/docs/reference/l10n-md) do repositório, porque nenhuma língua-alvo é selecionada no fluxo **Novo projeto**.

Até a primeira execução de tradução, o resumo do projeto exibe um aviso explicando que o Glossia aguarda uma push que inclua um `L10N.md` arquivo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo GitHub do Glossia pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Para a configuração automatizada, ao menos uma língua-alvo é selecionada.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando para completar. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em execução** | O Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade em tempo real. |
| **Concluído** | A linha de base de localização foi preparada e publicada para revisão. | Abra, revise e mescle a solicitação pull request. |

Os projetos são provisórios enquanto a configuração estiver **Pendente** ou **Em execução**. Se a configuração não puder finalizar ou publicar uma alteração utilizável, o Glossia limpa o ambiente da configuração e exclui o projeto provisório. O repositório torna-se então disponível no fluxo **Novo projeto** para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo novo-projeto e na visão geral do projeto. Inclui:

- Um distintivo de estado e barra de progresso.
- Uma breve explicação do estado atual.
- Atividades recentes de preparo, inspeção, modificação de arquivos, verificação e conclusão do repositório.
- Uma mensagem de falha clara quando a configuração não puder finalizar.

O progresso é armazenado enquanto o projeto provisório existir. Uma falha terminal descarta tanto o projeto como seu progresso de configuração visível.

## Resultado concluído

Uma configuração conectada bem-sucedida cria um ramo dedicado e uma solicitação pull request para a branch padrão do repositório. A solicitação pull request contém a linha de base de localização gerada, incluindo `L10N.md` contexto e as alterações práticas menores necessárias para carregar o conteúdo localizado.

A configuração não publica catálogos-alvo com apenas cabeçalhos. Quando um quadro de localização exige catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

O Glossia não mescla a solicitação pull request. Os mantenedores do repositório a revisam e a mesclam por meio de seu processo normal do GitHub.

O resumo do projeto exibe um aviso de configuração enquanto esta solicitação pull request está aberta. O aviso é removido após a solicitação pull request ser mesclada. Se a solicitação pull request for fechada sem ser mesclada, o resumo explica que ela deve ser reaberta antes de que a configuração possa ser considerada concluída.
