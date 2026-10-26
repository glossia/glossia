%{
  title: "Publicação de traduções",
  summary: "Reutilização de Pull request, agrupamento e limite de push global do projeto.",
  category: "Referência",
  section: "translation",
  order: 10
}
---

Glossia mantém uma única solicitação de pull de tradução aberta por projeto. Novos commits da branch padrão continuam sua branch em vez de abrir uma solicitação de pull para cada commit de origem. Uma nova solicitação de pull é criada após a anterior ser mesclada ou fechada.

Publicação e substituição de sessão compartilham uma trava de projeto suporta por banco de dados, inclusive quando executados em réplicas de aplicação diferentes ou runners desscolados. Se um runner criou uma solicitação de pull mas não pôde salvar seus metadados, a próxima publicação recupera a solicitação de pull do Glossia do GitHub antes de criar outra. Uma solicitação de pull aberta não é abandonada quando sua branch conflita com a origem ou o histórico da origem é reescrito: a sessão falha e mantém a publicação existente para resolução.

## Limite de envios

O limite é fixado em **4 envios por hora por projeto**, compartilhado entre sessões e réplicas. Não é atualmente configurável.

Os envios ficam espaçados uniformemente, não sendo contados em intervalos de hora fixos. As atualizações de branch estão separadas por pelo menos 15 minutos. O próximo intervalo começa quando uma tentativa de publicação termina, assim um lote lento não pode ser seguido imediatamente por um lote rápido. Mesclagens na branch de origem, lotes intermediários, tentativas de repetição e envios finais compartilham o mesmo orçamento. Tentativas de falha ambíguas também consomem um slot, porque o GitHub pode ter avançado a branch antes da conexão falhar. O orçamento é armazenado no PostgreSQL e não é resetado por uma nova sessão ou reinício de processo.

## Agrupamento de lotes

Uma execução coleta alterações de arquivo validadas e solicita publicação após 25 arquivos ou 15 minutos. Estes limites não ultrapassam o limite de envios. Durante um período de resfriamento, arquivos adicionais concluídos são adicionados ao lote pendente; alterações repetidas ao mesmo caminho mantêm o conteúdo mais recente.

Ao final da execução, o envio final aguarda o mesmo orçamento. A sessão permanece ativa e envia sinais de vida enquanto espera. Ela reverifica o cancelamento e a admissão periodicamente sem manter uma transação de banco de dados aberta enquanto estiver em repouso.
