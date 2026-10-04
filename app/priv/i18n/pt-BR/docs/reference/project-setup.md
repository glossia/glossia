%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "Referência",
  section: "translation",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Após o usuário selecionar um repositório para o **Novo projeto** fluxo, eles escolhem um dos dois modos de configuração.

## Modos de configuração

| Modo | O que o Glossia faz | Quando escolher isso |
|---|---|---|
| **Configuração automática** | Inspecciona o repositório e abre uma pull request com a gerada `L10N.md` configuração para as línguas-alvo selecionadas. | O repositório ainda não possui configuração de localização. |
| **Configuração manual** | Cria o projeto imediatamente. Não inspecciona o repositório, altera-o ou abre uma pull request. | O repositório já possui um `L10N.md` arquivo, ou um mantenedor o escreverá. |

Os estados, informações de progresso e a pull request descritos abaixo se aplicam apenas à configuração automática.

## Configuração manual

Um projeto configurado manualmente não possui estado de configuração. Ele é utilizável imediatamente após a criação e nunca é descartado por uma falha de configuração.

Glossia inicia uma execução de tradução no próximo push para a branch padrão do repositório. A execução traduz para todos os alvos declarados no repositório [`L10N.md`](/docs/reference/l10n-md) arquivos, porque nenhum idioma-alvo está selecionado no **Novo projeto** fluxo.

Até a primeira execução de tradução, a visão geral do projeto exibe um aviso explicando que o Glossia aguarda um push que contenha um `L10N.md` arquivo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Para configuração automática, pelo menos um idioma de destino foi selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando o início. | Acompanhe o progresso ou saia da página e volte mais tarde. |
| **Em andamento** | Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e realize o merge do pull request. |

Os projetos são provisórios enquanto a configuração está **Pendente** ou **Em execução**. Se a configuração não puder finalizar ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um distintivo de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem clara de falha quando a configuração não puder ser concluída.

O progresso é armazenado enquanto o projeto provisório existir. Uma falha terminal descarta tanto o projeto quanto seu progresso de configuração visível.

## Resultado concluído

Uma configuração conectada bem-sucedida cria um ramo dedicado e um pull request contra o ramo padrão do repositório. O pull request contém o baseline de localização gerado, incluindo `L10N.md` contexto e as menores alterações práticas necessárias para carregar conteúdo localização.

A Configuração não publica catálogos-alvo com apenas cabeçalhos. Quando um framework de localização exige catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagem de origem extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são necessários, a Configuração os deixa para a primeira execução da tradução.

O Glossia não incorpora o pull request. Os mantenedores do repositório revisam e o incorporam pelo processo normal do GitHub.

A visão geral do projeto exibe um aviso de Configuração enquanto este pull request estiver aberto. O aviso é removido após o pull request ser incorporado. Se o pull request for fechado sem ter sido incorporado, a visão geral explica que deve ser reaberto antes que a Configuração seja considerada finalizada.