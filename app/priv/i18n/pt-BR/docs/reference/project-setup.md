%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "Referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado ao Glossia. Ela começa após um usuário selecionar um repositório e pelo menos um idioma de destino no **Novo projeto** fluxo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma de destino está selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e aguarda o início. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em andamento** | Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e integre o pull request. |

Os projetos são provisórios enquanto a configuração está **Pendente** ou **Executando**. Se a configuração não puder finalizar ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um indicador de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação do repositório, inspeção, alteração de arquivo, verificação e conclusão.
- Uma mensagem de erro clara quando a configuração não consegue concluir.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha terminal descarta tanto o projeto quanto seu progresso visível de configuração.

## Resultado concluído

Uma configuração conectada bem-sucedida cria um ramo dedicado e um pull request contra o ramo padrão do repositório. O pull request contém a base de localização gerada, incluindo `L10N.md` contexto e as menores mudanças práticas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos alvo com apenas cabeçalhos. Quando um framework de localização exige catálogos alvo antes da tradução, os catálogos contêm as entradas de mensagens fonte extraídas com valores de tradução vazios. Quando os catálogos alvo ainda não são exigidos, a configuração os deixa para a primeira execução de tradução.

O Glossia não mescla o pull request. Os manutentores do repositório revisam e mesclam através de seu processo normal do GitHub.

A visão geral do projeto mostra um aviso de configuração enquanto este pull request está aberto. O aviso é removido após o pull request ser mesclado. Se o pull request for fechado sem ser mesclado, a visão geral explica que ele deve ser reaberto antes que a configuração possa ser considerada finalizada.