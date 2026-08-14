%{
  title: "Configuração do projeto",
  summary: "Estados, informações de progresso e resultados da configuração do repositório.",
  category: "reference",
  order: 2
}
---
A configuração do projeto prepara um repositório conectado para o Glossia. Ela começa depois que o usuário seleciona um repositório e pelo menos um idioma de destino no fluxo **Novo projeto**.

## Pré-requisitos

- A conta tem pelo menos um modelo configurado.
- O aplicativo do Glossia para GitHub pode acessar o repositório selecionado.
- O usuário pode criar projetos na conta.
- Pelo menos um idioma de destino está selecionado.

## Estados

| Estado | Significado | Ação disponível |
|---|---|---|
| **Pendente** | O projeto foi aceito e está aguardando o início. | Acompanhe o progresso ou saia da página e retorne mais tarde. |
| **Em execução** | O Glossia está inspecionando e atualizando o repositório. | Acompanhe a atividade em tempo real. |
| **Concluído** | A base de localização foi preparada e publicada para revisão. | Abra, revise e faça o merge da pull request. |

Os projetos são provisórios enquanto a configuração está **Pendente** ou **Em execução**. Se não for possível concluir a configuração ou publicar uma alteração utilizável, o Glossia limpa o ambiente de configuração e exclui o projeto provisório. O repositório fica disponível novamente no fluxo **Novo projeto**, permitindo uma nova tentativa de configuração.

## Progresso visível

O cartão de configuração permanece disponível no fluxo de novo projeto e na visão geral do projeto. Ele inclui:

- Um indicador de estado e uma barra de progresso.
- Uma breve explicação do estado atual.
- Atividades recentes de preparação e inspeção do repositório, alterações de arquivos, verificações e conclusão.
- Uma mensagem de falha clara quando não for possível concluir a configuração.

O progresso é armazenado enquanto o projeto provisório existe. Uma falha terminal descarta tanto o projeto quanto o progresso visível da configuração.

## Resultado concluído

Uma configuração conectada bem-sucedida cria uma branch dedicada e uma pull request direcionada à branch padrão do repositório. A pull request contém a base de localização gerada, incluindo o contexto `GLOSSIA.md` e as menores alterações viáveis necessárias para carregar o conteúdo localizado.

A configuração não publica catálogos de destino que contenham apenas o cabeçalho. Quando uma estrutura de localização exige catálogos de destino antes da tradução, os catálogos contêm as entradas de mensagens extraídas da origem com valores de tradução vazios. Quando os catálogos de destino ainda não são necessários, a configuração os deixa para a primeira execução de tradução.

O Glossia não faz o merge da pull request. Os mantenedores do repositório a revisam e fazem o merge por meio do processo habitual no GitHub.

A visão geral do projeto exibe um aviso de configuração enquanto essa pull request estiver aberta. O aviso é removido depois que o merge da pull request é concluído. Se a pull request for fechada sem merge, a visão geral informa que ela deve ser reaberta para que a configuração possa ser considerada concluída.