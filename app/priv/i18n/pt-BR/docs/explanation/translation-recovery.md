%{
  title: "Recuperação de tradução",
  summary:
    "Como a Glossia mantém o Markdown intacto e se recupera da limitação do provedor e das traduções interrompidas.",
  category: "explicação",
  section: "translation",
  order: 8
}
---

O Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva esse requisito: uma nova tentativa deve ainda preservar a estrutura da fonte e os espaços reservados necessários, e cada arquivo montado passa nos comandos de validação configurados.

## Tradução de Markdown

O Glossia nunca re-renderiza um documento Markdown traduzido. Ele analisa a fonte apenas para encontrar seu texto corrido: parágrafos, títulos, itens de lista, células de tabela, os atributos voltados para o leitor de componentes e HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), e o texto de um HTML `<summary>`. Cada tradução é escrita de volta nos bytes exatos que sua fonte ocupava, então código, destinos de link, componentes, alertas do GitHub, âncoras de títulos explícitas como `{#install}`, marcadores de lista e linhas em branco permanecem idênticos byte a byte.

Cada parágrafo ou título é traduzido como uma frase inteira. A formatação em linha torna-se tags numeradas: `<gN>...</gN>` ao redor de palavras vinculadas ou enfatizadas, e `<gN/>` para conteúdo que não deve mudar, como código em linha ou um componente. O modelo pode mover tags para seguir a ordem de palavras da linguagem-alvo, mas deve manter cada tag exatamente uma vez. Cada solicitação também traz o documento de origem circundante, e as traduções mais recentes do mesmo arquivo, para referência.

Uma unidade que perde ou inventa uma tag é enviada novamente por conta própria, com o motivo, até três vezes. Unidades que voltaram válidas são mantidas. Após a colagem, o Glossia analisa o resultado e compara sua estrutura com a fonte. Uma tradução que se tornaria um título, lista ou ênfase por si mesma tem o texto escapeado, o que não precisa de chamada adicional de modelo.

## Tradução de catálogos

Os catálogos Gettext são analisados em strings antes da tradução. As solicitações carregam no máximo oito strings, com um alvo de agrupamento de 8.000 bytes. Uma única string maior permanece intacta. O modelo retorna um array com o mesmo número de strings na mesma ordem. O Glossia verifica variáveis de interpolação e rejeita traduções vazias.

Os cabeçalhos são construídos em código usando as regras de plural da localização-alvo. Identificadores de mensagens de origem, comentários e estrutura de catálogo vêm da fonte analisada. Se um lote retornar conteúdo inválido, o Glossia o reenvia uma vez, depois divide-o em lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Limitação de provedor

O Glossia coordena solicitações de tradução que usam a mesma credencial e modelo. Uma resposta de limite de taxa estende seu tempo de resfriamento compartilhado e aumenta o espaçamento entre novas solicitações. O tráfego bem-sucedido reduz gradualmente esse espaçamento após um minuto sem limitação. Solicitações já em execução são permitidas para terminar.

As dicas de tentativas de envio do provedor são atrasos mínimos. Falhas repetidas também aumentam o backoff, até um atraso base de 30 segundos mais jitter. Um indicador de provedor mais longo tem precedência, limitado a cinco minutos. O cabeçalho `x-ratelimit-reset` do Together é reconhecido juntamente com o `retry-after`.

Após oito tentativas de solicitação não concluídas, a execução do repositório para de iniciar novos arquivos. Uma continuidade atrasada herda a branch de tradução e retoma seu trabalho inacabado. A tentativa anterior permanece visível no histórico de sessão, ligada pela continuidade. Os atrasos aumentam de um minuto para cinco minutos, com no máximo seis continuovas automáticas. Sessões mais recentes e ativas têm precedência, e sessões canceladas nunca são reativadas. Falhas de validação por si só não agendam recuperação do provedor.

## Recuperação após lançamento da engine

Uma sessão tem duas versões independentes: o commit do repositório sendo traduzido e a imagem da engine de tradução executando-o. No Kubernetes, cada job fixa o resumo exato da imagem da réplica web que o agendou. Os jobs sobrevivem às implantações web e nunca trocam código no meio de uma tradução. Um job agendado logo antes de uma implantação pode, portanto, terminar na engine anterior mesmo após o aplicativo web atualizado. Os detalhes da sessão mostram o resumo da engine; sessões mais antigas sem essa proveniência exibem "Não registrado."

A cada cinco minutos, o Glossia verifica se sua implantação foi totalmente lançada. Apenas um worker dessa implantação saudável pode agendar recuperação da engine. Se a sessão mais recente de um projeto foi agendada antes que essa implantação concluísse, rodou em um resumo de engine mais antigo registrado e falhou em seguida nas últimas seis horas, o Glossia pode criar uma continuidade no lançamento atual. Usando o tempo de fila também cobre jobs que esperam capacidade e só iniciam após a implantação. Um resumo de imagem diferente por si só não aciona re-tentativas de falhas comuns após implantações não relacionadas. Arquivos concluídos e o pull request de tradução aberto permanecem; apenas o trabalho inacabado é traduzido novamente. Continuidades de lançamentos agendadas aguardam enquanto uma implantação está em andamento, por no máximo 15 minutos. Falhas de API ou permissões do Kubernetes param o lançamento com um erro explícito em vez de serem confundidas com uma implantação em andamento.

A recuperação é deliberadamente restritiva: a sessão deve ter terminado com uma falha de validação de item registrada, e cada item falhado em sua última tentativa deve relatar uma falha de estrutura Markdown, conteúdo preservado ou unidade Markdown. Tentativas interrompidas ou parcialmente canceladas não se qualificam. Erros do provedor, crédito esgotado, credenciais rejeitadas, falhas de publicação, erros de leitura de fonte, falhas de comando de validação externa e causas desconhecidas não são re-tentados por uma implantação. Sessões bem-sucedidas, ativas, canceladas, suplantadas e não versionadas também são mantidas. Uma sessão mais recente sempre vence, mesmo que o usuário a tenha cancelado.

Uma sessão recebe no máximo uma continuidade em um lançamento de engine diferente, com no máximo três continuidades de lançamento em uma linhagem. Se a nova engine ainda falhar, não será re-tentada novamente naquela mesma imagem, incluindo após um rollback. A linhagem mantém seus resumos de engine tentados anteriormente, e o lançador os verifica novamente antes de criar um job agendado. Os limites de recuperação do provedor existentes são preservados através das continuidades de lançamento. Tags de imagem mutáveis e implantações sem uma identidade de lançamento configurada não permitem recuperação automática da engine.

## Progresso durável

Arquivos concluídos e seus lockfiles são publicados ao ramo de tradução em lotes: um commit para cada 25 arquivos, ou a cada 15 minutos, e um commit final quando a execução termina. Cada push executa as verificações de pull request do repositório, de modo que o loteamento evita iniciar uma execução de verificação individual por arquivo. Um projeto possui um único pull request de tradução: um novo commit no ramo padrão continua o aberto e traduz apenas o que mudou desde então. Quando esse pull request for mesclado ou fechado, a próxima execução inicia um novo. Dentro dos arquivos inacabados, segmentos validados localmente e lotes de recuperação são também salvos no banco de dados por sete dias. Esses checkpoints sobrevivem à interrupção de um processo do trabalhador. Eles são delimitados pela conta, projeto, entrada do documento, credencial e modelo efetivos, contexto e segmento ou tentativa de reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda coincidem. Sempre valida novamente o documento final montado. Respostas do modelo rejeitadas não são checkpoints. Uma falha de validação no nível do documento inicia uma tentativa de reparo separada porque o validador pode não identificar um único segmento responsável.

Pontos de controle expirados e registros de taxa do provedor inativos são removidos pelo trabalhador de recuperação de sessão agendado. Estes são registros operacionais; os usuários não precisam adicioná-los ao seu repositório ou configurá-los em `L10N.md`.
