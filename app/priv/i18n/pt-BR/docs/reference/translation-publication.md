%{
  title: "Publicação de tradução",
  summary: "Reutilização de pull requests, agrupamento e o limite de push em nível do projeto.",
  category: "referência",
  section: "translation",
  order: 10
}
---

A Glossia mantém uma única pull request de tradução aberta por projeto. Novos commits do ramo padrão continuam a atualizar o seu ramo, em vez de abrir uma pull request para cada commit da origem. Uma nova pull request é criada após a anterior ser mesclada ou fechada.

Uma publicação e substituição de sessão compartilham um travamento de projeto suportado por banco de dados, inclusive quando executam em diferentes réplicas de aplicação ou runners desconectados. Se um runner criou uma pull request mas não pôde salvar os metadados, a próxima publicação recupera a pull request da Glossia aberta no GitHub antes de criar outra. Uma pull request aberta não é abandonada quando seu ramo entra em conflito com a origem ou o histórico da origem é reescrito: a sessão falha e mantém a publicação existente para resolução.

## Limite de publicações

O limite é fixo em **4 publicações por hora por projeto**, compartilhado entre sessões e réplicas. Atualmente não é configurável.

Os envios são espaçados uniformemente, não contados em recipientes de hora fixa do relógio. As atualizações do ramo são espaçadas de pelo menos 15 minutos. O próximo intervalo começa quando uma tentativa de publicação termina, de modo que um lote lento não pode ser seguido imediatamente por um rápido. Mesclagens do ramo de origem, lotes intermediários, redemistas e esvaziamentos finais compartilham a mesma cota. Tentativas de falha ambíguas também consomem uma cota, porque o GitHub pode ter avançado o ramo antes que a conexão falhasse. A cota é armazenada no PostgreSQL e não é reiniciada por uma nova sessão ou reinício do processo.

## Loteamento

Uma execução coleta alterações de arquivo validadas e solicita publicação após 25 arquivos ou 15 minutos. Esses limites não contornam o limite de publicações. Durante um período de espera, arquivos concluídos adicionais são adicionados ao lote pendente; alterações repetidas no mesmo caminho mantêm o conteúdo mais recente.

Ao final da execução, o esvaziamento final aguarda a mesma cota. A sessão permanece ativa e envia sinais de vida enquanto aguarda. Ela reverifica o cancelamento e a admissão periodicamente sem manter uma transação de banco de dados aberta enquanto estiver ociosa.
