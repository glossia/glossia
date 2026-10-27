%{
  title: "Publicação de tradução",
  summary:
    "Reutilização de solicitações de pull, processamento em lote e o limite de push global do projeto.",
  category: "Referência",
  section: "translation",
  order: 10
}
---

O Glossia mantém uma única solicitação pull de tradução aberta por projeto. Novos commits do ramo padrão continuam o ramo ao invés de abrir uma solicitação pull para cada commit da fonte. Uma nova solicitação pull é criada após a anterior ser mesclada ou fechada. Uma publicação fechada recebe um nome de ramo fresco, inclusive ao reprocessar o mesmo commit da fonte; suas saídas rejeitadas não são reutilizadas como trabalho concluído.

A sincronização da fonte ocorre em um checkout local descartável antes da avaliação, preservando as traduções concluídas e os lockfiles do ramo aberto. Uma execução que não encontra alterações na saída ou nos lockfiles não avança o ramo remoto meramente para se atualizar com o ramo padrão, e não gasta um slot de publicação. Quando um lote está pronto, a sincronização da fonte e as alterações validadas são publicadas juntas em uma atualização de ramo não forçada. O commit retém tanto a publicação anterior quanto o commit da fonte avaliado como ancestrais.

Publicação e substituição de sessão compartilham um bloqueio de projeto respaldado por banco de dados, inclusive quando executados em réplicas de aplicação diferentes ou runners desconectados. Se um runner criar uma solicitação pull mas não puder salvar seus metadados, a próxima publicação recupera a solicitação pull do Glossia aberta do GitHub antes de criar outra. Uma solicitação pull aberta não é abandonada quando seu ramo conflita com a fonte ou o histórico da fonte é reescrito: a sessão falha e retém a publicação existente para resolução.

## Limite de envio

O limite está fixado em **4 envios por hora por projeto**, compartilhado entre sessões e réplicas. Atualmente não é configurável.

Os envios estão espaçados uniformemente, não contados em intervalos de hora fixa. As atualizações de ramo têm pelo menos 15 minutos de intervalo entre si. O próximo intervalo começa quando uma tentativa de publicação termina, por isso um lote lento não pode ser seguido imediatamente por um rápido. Lotes intermediários, tentativas de repetição e finalizações finais compartilham o mesmo orçamento. Tentativas de falha ambíguas consomem um slot também, porque o GitHub pode ter avançado o ramo antes de uma conexão falhar. O orçamento é armazenado em PostgreSQL e não é reiniciado por uma nova sessão ou reinício de processo.

Antes da publicação, o Glossia relê a ponta (head) remota e mescla a fonte da sessão novamente localmente. Isso preserva lotes anteriores e detecta conflitos sem mover o ramo. Se uma atualização anterior tiver sucesso, mas sua resposta for perdida, as alterações já presentes não são commitadas novamente; os metadados de publicação e a solicitação pull são recuperados sem outra atualização de ramo. Se o ref foi criado, mas o runner parou antes de criar sua solicitação pull, uma avaliação sem alteração ainda cria a solicitação pull faltante, sem gastar um slot de atualização de ramo.

Um avanço remoto inesperado é aceito apenas quando suas diferenças da árvore sincronizada esperada são partes do lote pendente já presentes. Outras edições feitas durante a avaliação falham na publicação em vez de serem sobrescritas ou publicar traduções validadas com base em entradas desatualizadas. A solicitação pull existente é retida para resolução.

## Lotes

Uma execução coleta alterações de arquivos validadas e solicita publicação após 25 arquivos ou 15 minutos. Esses limites não contornam o limite de envio. Durante o período de espera, arquivos concluídos adicionais se juntam ao lote pendente; alterações repetidas ao mesmo caminho mantêm o conteúdo mais recente.

No final da execução, a finalização aguarda pelo mesmo orçamento. A sessão permanece ativa e envia pings enquanto espera. Ela verifica periodicamente o cancelamento e a admissão sem manter uma transação de banco de dados aberta enquanto adormecida.
