%{
  title: "Recuperação de tradução",
  summary:
    "Como o Glossia mantém o Markdown intacto e se recupera de limitações de provedores e traduções interrompidas.",
  category: "explicação",
  section: "translation",
  order: 8
}
---
A Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva
essa exigência: uma nova tentativa deve ainda preservar a estrutura de origem e obrigatórios
locais reservados, e cada arquivo montado passa em seus comandos de validação configurados.

## Tradução de Markdown

Glossia nunca re-renderiza um documento Markdown traduzido. Ele analisa a fonte
apenas para encontrar seu texto escrito: parágrafos, cabeçalhos, itens de lista, células de tabela, o
os atributos dos componentes voltados para o leitor e HTML (`title`) `details`O documento reunido anteriormente falhou na validação: a recuperação de texto-literal do Markdown deve retornar um array de strings JSON de comprimento correspondente. `alt`O documento reunido anteriormente falhou na validação: a recuperação de texto literal do Markdown deve retornar um array de strings JSON de comprimento correspondente
`label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), e
o texto de um HTML `<summary>`. Cada tradução é reescrita de volta para o exato
bytes que sua origem ocupava, então código, destinos de link, componentes, GitHub
alertas, âncoras de cabeçalho explícitas como `{#install}`, marcadores de lista e em branco
linhas permanecem idênticas byte a byte.

Cada parágrafo ou cabeçalho é traduzido como uma frase inteira. Formatação em linha
torna-se tags numeradas: `<gN>...</gN>` Ao redor de palavras vinculadas ou destacadas, e
`<gN/>` para conteúdo que não deve mudar, como código em linha ou um componente.
O modelo pode mover etiquetas para seguir a ordem das palavras da língua-alvo, mas deve
manter cada etiqueta exatamente uma vez. Cada requisição também inclui o texto fonte ao redor do,
documento, e as traduções mais recentes do mesmo arquivo, para referência.

Uma unidade que perde ou cria uma etiqueta é enviada novamente de forma isolada, com o motivo,
até três vezes. Unidades que retornaram válidas são mantidas. Após a união, Glossia
analisa o resultado e compara sua estrutura com a fonte. Uma tradução que
que sozinha viraria um título, lista ou ênfase tem seu texto escapado,
o que não precisa de mais nenhuma chamada ao modelo.

## Tradução de catálogo

Os catálogos Gettext são convertidos em strings antes da tradução. As requisições carregam no
máximo de oito strings, com uma meta de loteamento de 8.000 bytes. Uma string maior individual
permanece intacta. O modelo retorna um array com o mesmo número de strings no
mesma ordem. O Glossia verifica as variáveis de interpolação e rejeita traduções vazias.

Mensagem de origem
identificadores, comentários e estrutura do catálogo vêm da fonte analisada. Se um
lote retorna conteúdo malformado, a Glossia tenta novamente uma vez e, em seguida, divide-o em
lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Limitação do provedor

A Glossia coordena solicitações de tradução que usam a mesma credencial e modelo. Um limite de taxa
resposta estende seu período de resfriamento compartilhado e aumenta o espaçamento entre novas solicitações.
Tráfego bem-sucedido reduz gradualmente esse espaçamento após um minuto sem limitação.
Solicitações já em execução são permitidas para terminar.

As dicas de retry do provedor são atrasos mínimos. Falhas repetidas também aumentam o
backoff, até um atraso base de 30 segundos mais jitter; uma dica de provedor mais longa tem
precedência, limitado a cinco minutos. do Together `x-ratelimit-reset` o cabeçalho é
reconhecido ao lado `retry-after`.

Depois de oito tentativas de requisição não bem-sucedidas, a execução do repositório para de iniciar novos
arquivos. Uma continuação atrasada herda a branch de tradução e retoma sua
trabalho inacabado. A tentativa anterior permanece visível no histórico de sessão, vinculada
através da continuidade. Os atrasos aumentam de um minuto para cinco minutos, com
no máximo seis continuações automáticas. Sessões ativas mais recentes têm prioridade, e
sessões canceladas nunca são restauradas. Falhas de validação por si só não agendam
a recuperação do provedor.

## Progresso durável

Arquivos concluídos e seus arquivos de bloqueio são publicados no ramo de tradução em
lotes: um comit para cada 25 arquivos, ou a cada 15 minutos, e um comit final
quando a execução termina. Cada push executa as verificações de solicitação de pull do repositório, então
o agrupamento impede que uma grande execução inicie uma verificação por arquivo. Um projeto tem
uma única solicitação de pull de tradução: um novo comit no ramo padrão continua
a que está aberta, e traduz apenas o que mudou desde então. Uma vez que aquela solicitação de pull esteja
mesclada ou fechada, a próxima execução inicia uma nova. Dentro dos arquivos inacabados, segmentos validados localmente e lotes de recuperação
também são salvos no banco de dados por sete dias. Estes checkpoints sobrevivem a um trabalhador
processo interrompido. Eles são limitados à conta, ao projeto, à entrada do documento,
credencial efetiva e modelo, contexto, e segmento ou tentativa de reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda coincidem. Sempre
valida o documento final montado novamente. Respostas do modelo rejeitadas não são
pontos de controle. Uma falha de validação no nível do documento inicia uma tentativa de reparo separada
porque o validador pode não identificar um único segmento responsável.

Pontos de controle expirados e registros de ritmo do provedor inativos são removidos pelo
trabalhador de recuperação de sessão agendada. Estes são registros operacionais; os usuários não
é necessário adicioná-los ao seu repositório ou configurá-los em `L10N.md`.