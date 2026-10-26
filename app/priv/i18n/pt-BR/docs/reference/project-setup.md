%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  section: "translation",
  order: 2
}
---

A configuração do projeto prepara um repositório conectado para o Glossia. Após um usuário selecionar um repositório no fluxo **Novo projeto**, o usuário escolhe um dos dois modos de configuração.

## Modos de configuração

| Modo | O que o Glossia faz | Quando escolher |
|---|---|---|
| **Configuração automatizada** | Inspeciona o repositório e abre um pull request com a configuração `L10N.md` gerada para as linguagens-alvo selecionadas. | O repositório ainda não tem configuração de localização. |
| **Configuração manual** | Cria o projeto imediatamente. Não inspeciona o repositório, não o altera, nem abre um pull request. | O repositório já possui um arquivo `L10N.md`, ou um mantenedor o escreverá. |

Os estados, as informações de progresso e o pull request descritos a seguir aplicam-se apenas à configuração automatizada.

## Configuração manual

Um projeto com configuração manual não possui estado de configuração. Ele é utilizável assim que é criado e nunca é descartado por uma configuração falha.

O Glossia inicia uma execução de tradução no próximo push para a branch padrão do repositório. A execução traduz para cada alvo declarado nos arquivos [`L10N.md`](/docs/reference/l10n-md) do repositório, porque nenhuma linguagem-alvo foi selecionada no fluxo **Novo projeto**.

Até a primeira execução de tradução, a visão geral do projeto exibe um aviso explicando que o Glossia aguarda um push que inclua um arquivo `L10N.md`.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Para a configuração automatizada, pelo menos uma linguagem-alvo foi selecionada.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e aguarda para iniciar. | Acompanhe o progresso ou saia da página e retorne depois. |
| **Em execução** | O Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade ao vivo. |
| **Concluído** | A linha base de localização foi preparada e publicada para revisão. | Abra, revise e faça o merge do pull request. |

Os projetos são provisórios enquanto a configuração está **Pendente** ou **Em execução**. Se a configuração não puder acabar ou publicar uma mudança utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório então fica disponível no fluxo **Novo projeto** para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um distintivo de estado e barra de progresso.
- Uma explicação breve do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem de erro clara quando a configuração não pode ser concluída.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha terminal descarta tanto o projeto quanto seu progresso de configuração visível.

## Resultado concluído

Uma configuração conectada bem-sucedida cria uma branch dedicada e um pull request na branch padrão do repositório. O pull request contém a linha base de localização gerada, incluindo `L10N.md` contexto e as alterações práticas menores necessárias para carregar conteúdo localizado.

A configuração não publica catálogos de alvo apenas com cabeçalhos. Quando um framework de localização exige catálogos de alvo antes da tradução, os catálogos contêm as entradas de mensagem extraídas da fonte com valores de tradução vazios. Quando os catálogos de alvo ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

O Glossia não merge o pull request. Os mantenedores do repositório o revisam e o merge através do processo normal do GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto este pull request está aberto. O aviso é removido após o merge do pull request. Se o pull request for fechado sem ter sido merge, a visão geral explica que ele precisa ser reaberto antes que a configuração possa ser considerada concluída.
