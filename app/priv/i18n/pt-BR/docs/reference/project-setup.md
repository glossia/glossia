%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "Referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Ela começa após um usuário selecionar um repositório e pelo menos um idioma de destino no **Novo projeto** fluxo.

## Pré-requisitos

- A conta tem pelo menos um modelo configurado.
- O aplicativo do Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma de destino foi selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando iniciar. | Acompanhe o progresso ou saia da página e volte depois. |
| **Em execução** | O Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e faça o merge do pull request. |

Os projetos são provisórios enquanto a configuração estiver **Pendente** ou **Em andamento**. Se a configuração não puder finalizar ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

Este cartão de configuração permanece disponível no fluxo Novo projeto e na visão geral do projeto. Ele inclui:

- Um badge de estado e barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem de falha clara quando a configuração não puder ser concluída.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha fatal descarta tanto o projeto quanto seu progresso visível da configuração.

## Resultado concluído.

Uma configuração conectada bem-sucedida cria um ramo dedicado e uma solicitação de pull contra o ramo padrão do repositório. A solicitação de pull contém a base de localização gerada, incluindo `L10N.md` contexto e as alterações práticas mínimas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos alvo com apenas cabeçalhos. Quando um framework de localização exige catálogos alvo antes da tradução, os catálogos contêm as entradas de mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos alvo ainda não são necessários, a configuração deixa-os para a primeira execução de tradução.

O Glossia não funde a solicitação de pull. Os mantenedores do repositório a revisam e fundem através do processo normal deles no GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto esta solicitação de pull está aberta. O aviso é removido após a solicitação de pull ser fundida. Se a solicitação de pull for fechada sem ter sido fundida, a visão geral explica que ela deve ser reaberta antes que a configuração possa ser considerada concluída.