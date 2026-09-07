%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "referência",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para Glossia. Ela começa após o usuário selecionar um repositório e pelo menos um idioma-alvo no **Novo projeto** fluxo.

## Pré-requisitos

- A conta possui pelo menos um modelo configurado.
- O aplicativo Glossia GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma-alvo é selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando início. | Acompanhamento do progresso ou sair da página e retornar depois. |
| **Em execução** | Glossia examina e atualiza o repositório. | Acompanhamento da atividade em tempo real. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e mescale a solicitação de pull. |

Os projetos são provisórios enquanto a configuração estiver **Pendente** ou **Em execução**. Se a configuração não puder terminar ou publicar uma alteração utilizável, Glossia limpa o ambiente da configuração e excluir o projeto provisório. O repositório então se torna disponível no **Novo projeto** fluxo para que a configuração possa ser tentada novamente.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Inclui:

- Um distintivo de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividade recente de preparação, inspeção, alteração de arquivo, verificação e conclusão do repositório.
- Uma mensagem de falha clara quando a configuração não puder ser concluída.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha terminal descarta tanto o projeto quanto o progresso de configuração visível.

## Resultado concluído

Uma configuração conectada bem-sucedida cria uma branch dedicada e uma solicitação de pull contra a branch padrão do repositório. A solicitação de pull contém a base de localização gerada, incluindo `GLOSSIA.md` de contexto e as menores alterações práticas necessárias para carregar conteúdo localizado.

A configuração não publica catálogos-alvo apenas com cabeçalho. Quando um framework de localização exige catálogos-alvo antes da tradução, os catálogos contêm as entradas de mensagens extraídas com valores de tradução vazios. Quando os catálogos-alvo ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

Glossia não mescla a solicitação de pull. Os mantenedores do repositório revisam e mesclam através de seu processo normal no GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto essa solicitação de pull está aberta. O aviso é removido após a solicitação de pull ser mesclada. Se a solicitação de pull for fechada sem ser mesclada, a visão geral explica que ela deve ser reaberta antes que a configuração seja considerada concluída.