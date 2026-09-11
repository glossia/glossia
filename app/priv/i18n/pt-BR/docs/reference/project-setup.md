%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Começa após um usuário selecionar um repositório e pelo menos uma linguagem de destino no **Novo projeto** fluxo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O Glossia GitHub App pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos uma linguagem de destino está selecionada.

## Estados

| Estado | Descrição | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando o início. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em andamento** | Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade em tempo real. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e integre o pull request. |

Os projetos são provisórios enquanto a configuração está **Pendente** ou **Em execução**. Se o processo de configuração não puder ser finalizado ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um indicador de estado e barra de progresso.
- Uma breve explicação do estado atual.
- Atividades recentes de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem clara de erro quando a configuração não pode ser concluída.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha fatal descarta tanto o projeto quanto seu progresso visível de configuração.

## Resultado concluído

Uma configuração conectada com sucesso cria uma branch dedicada e um pull request contra a branch padrão do repositório. O pull request contém a base de localizações gerada, incluindo `L10N.md` contexto e as menores alterações práticas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos de destino com apenas cabeçalhos. Quando um framework de localização exige catálogos de destino antes da tradução, os catálogos contêm as entradas das mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos de destino ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

Glossia não funde o pull request. Os mantenedores do repositório o revisam e fundem por meio de seu processo normal do GitHub.

A visão geral do projeto mostra um aviso de configuração enquanto este pull request está aberto. O aviso é removido após o pull request ser fundido. Se o pull request for fechado sem ser fundido, a visão geral explica que ele deve ser reaberto antes que a configuração possa ser considerada concluída.