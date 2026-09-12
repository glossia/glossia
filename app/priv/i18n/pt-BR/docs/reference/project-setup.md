%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado ao Glossia. Ela começa após o usuário selecionar um repositório e pelo menos um idioma de destino em o **Novo projeto** fluxo.

## Pré-requisitos

- A conta tem pelo menos um modelo configurado.
- O aplicativo do Glossia para o GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma de destino é selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando início. | Acompanhe o progresso ou saia da página e volte depois. |
| **Em andamento** | Glossia está verificando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e integre o pull request. |

Projetos são provisórios enquanto a configuração está **Pendente** ou **Em andamento**. Se a configuração não puder terminar ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e deleta o projeto provisório. O repositório então se torna disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Inclui:

- Um indicador de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem de falha clara quando a configuração não consegue ser concluída.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha terminal descarta tanto o projeto quanto seu progresso visível de configuração.

## Resultado completado

Uma configuração conectada bem-sucedida cria um ramo dedicado e uma solicitação de pull contra o ramo padrão do repositório. A solicitação de pull contém a base de localização gerada, incluindo `L10N.md` contexto e as alterações mínimas e práticas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos-alvo apenas de cabeçalho. Quando um framework de localização exige catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagens de origem extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são exigidos, a configuração deixa-os para a primeira execução de tradução.

A Glossia não mescla a solicitação de pull. Os manutenedores do repositório revisam e mesclam-a por meio do processo habitual do GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto essa solicitação de pull estiver aberta. O aviso é removido após a solicitação de pull ser mesclada. Se a solicitação de pull estiver fechada sem ter sido mesclada, a visão geral explica que ela deve ser reaberta antes que a configuração possa ser considerada finalizada.