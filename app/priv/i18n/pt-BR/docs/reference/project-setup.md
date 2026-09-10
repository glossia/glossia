%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Ela começa após um usuário selecionar um repositório e pelo menos um idioma de destino em o **Novo projeto** fluxo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma de destino é selecionado.

## Estados

| Estado | Descrição | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando o início. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em andamento** | Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade em tempo real. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e mesclle o Pull Request. |

Projetos são provisórios enquanto a configuração está **Pendente** ou **Em andamento**. Se a configuração não puder ser concluída ou publicar uma mudança utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um marcador de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem de falha clara quando a configuração não puder ser concluída.

O progresso é armazenado enquanto o projeto provisório existir. Uma falha terminal descarta tanto o projeto quanto o seu progresso visível de configuração.

## Resultado concluído

Uma configuração conectada com sucesso cria um ramo dedicado e uma pull request contra o ramo padrão do repositório. A pull request contém a base de localização gerada, incluindo `L10N.md` contexto e as menores alterações práticas necessárias para carregar o conteúdo localizado.

A configuração não publica catálogos-alvo com apenas cabeçalho. Quando um framework de localização requer catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

A Glossia não mescla a pull request. Os mantenedores do repositório revisam e mesclam através do processo normal do GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto o pull request está aberto. O aviso é removido após o pull request ser mesclado. Se o pull request for fechado sem ser mesclado, a visão geral explica que ele deve ser reaberto antes que a configuração possa ser considerada concluída.