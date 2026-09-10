%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Ela começa após um usuário selecionar um repositório e pelo menos um idioma alvo no **Novo projeto** fluxo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo do Glossia no GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma alvo foi selecionado.

## Estados

| Estado | Descrição | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando para começar. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em andamento** | O Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Completado** | A linha de base de localização foi preparada e publicada para revisão. | Abra, revise e integre o pull request. |

Projetos são provisórios enquanto a configuração está **Pendente** ou **Em andamento**. Se a configuração não puder terminar ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e remove o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para tentar novamente a configuração.

## Progresso visível

O cartão de configuração permanece disponível no fluxo do novo projeto e na visão geral do projeto. Inclui:

- Um emblema de estado e barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem clara de falha quando a configuração não pode ser concluída.

O progresso é armazenado enquanto o projeto provisório existir. Uma falha terminal descarta tanto o projeto quanto seu progresso de configuração visível.

## Resultado concluído

Uma configuração conectada bem-sucedida cria um ramo dedicado e uma solicitação de pull contra o ramo padrão do repositório. A solicitação de pull contém a base de localização gerada, incluindo `L10N.md` contexto e as alterações práticas mínimas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos-alvo apenas de cabeçalhos. Quando um framework de localização exige catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

Glossia não mescla a solicitação de pull. Os mantenedores do repositório a revisam e mesclam através do processo normal do GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto esta solicitação de pull está aberta. O aviso é removido após a solicitação de pull ser mesclada. Se a solicitação de pull for fechada sem ser mesclada, a visão geral explica que ela deve ser reaberta antes que a configuração seja considerada finalizada.