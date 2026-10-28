%{
  title: "Recuperação de tradução",
  summary:
    "Como o Glossia mantém o Markdown intacto e se recupera da limitação de taxa do provedor e traduções interrompidas.",
  category: "explicação",
  section: "translation",
  order: 8
}
---

O Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva esse requisito: um novo envio deve ainda preservar a estrutura da fonte e os placeholders obrigatórios, e cada arquivo montado passa pelos comandos de validação configurados.

## Tradução de Markdown

O Glossia nunca renderiza novamente um documento Markdown traduzido. Ele analisa a fonte apenas para encontrar sua prosa: parágrafos, títulos, itens de lista, células de tabela, os atributos de componentes e HTML voltados ao leitor (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), e o texto de uma tag HTML `<summary>`. Cada tradução é reescrita de volta no exato número de bytes que sua fonte ocupava, de modo que código, destinos de link, componentes, alertas do GitHub, âncoras de títulos explícitas como `{#install}`, marcadores de lista e linhas em branco permaneçam idêntico byte por byte.

Cada parágrafo ou título é traduzido como uma frase inteira. A formatação em linha se torna tags numeradas: `<gN>...</gN>` ao redor de palavras vinculadas ou enfatizadas, e `<gN/>` para conteúdo que não pode mudar, como código em linha ou um componente. O modelo pode mover tags para seguir a ordem das palavras da língua-alvo, mas deve manter cada tag exatamente uma vez. Cada solicitação também carrega o documento fonte circundante e as traduções mais recentes do mesmo arquivo, para referência.

Uma unidade que elimina ou inventa uma tag é enviada novamente de forma independente, com o motivo, até três vezes. Unidades que retornam válidas são mantidas. Após a colagem, o Glossia analisa o resultado e compara sua estrutura com a fonte. Uma tradução que se tornaria um título, lista ou ênfase por si só tem sua prosa escapada, o que não requer chamada adicional de modelo.

## Tradução de catálogo

Os catálogos Gettext são analisados em strings antes da tradução. Solicitações carregam no máximo oito strings, com um alvo de agrupamento de 8.000 bytes. Uma única string maior permanece intacta. O modelo retorna um array com o mesmo número de strings na mesma ordem. O Glossia verifica variáveis de interpolação e rejeita traduções vazias.

Os cabeçalhos são construídos no código usando as regras de plural da localidade-alvo. Identificadores de mensagem da fonte, comentários e estrutura do catálogo vêm da fonte analisada. Se um lote retornar conteúdo malformado, o Glossia reenvia-o uma vez, em seguida divide-o em lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Limitação de taxa do Provedor

O Glossia coordena solicitações de tradução que usam a mesma credencial e modelo. Uma resposta de limitação de taxa estende seu cooldown compartilhado e aumenta o espaçamento entre novas solicitações. O tráfego bem-sucedido gradualmente reduz esse espaçamento após um minuto sem limitação. Solicitações já em execução são autorizadas a terminar.

As dicas de nova tentativa do Provedor são atrasos mínimos. Falhas repetidas também aumentam o backoff, até um atraso de base de 30 segundos mais jitter; uma dica de Provedor mais longa tem precedência, limitada a cinco minutos. O cabeçalho `x-ratelimit-reset` da Together é reconhecido ao lado do `retry-after`.

Após oito tentativas requisitadas não bem-sucedidas, a execução do repositório para de iniciar novos arquivos. Uma continuação atrasada herda a branch de tradução e retoma seu trabalho inacabado. A tentativa anterior permanece visível no histórico da sessão, vinculada através da continuação. A atrasos aumentam de um minuto para cinco minutos, com no máximo seis contínuos automáticos. Sessões ativas mais recentes tomam precedência e sessões canceladas nunca são revividas. Falhas de validação sozinhas não agendam a recuperação do Provedor.

## Recuperação após um lançamento do motor

**Edição: Enterprise.** As verificações de implantação do Kubernetes e a recuperação após um lançamento do motor descritas nesta seção exigem [runners de tradução isolados](/pt-br/docs/reference/isolated-translation-runners). A recuperação de Markdown, catálogos e provedores, além do progresso durável descritos no restante desta página, continuam disponíveis no Community.

Uma sessão tem duas versões independentes: o commit do repositório sendo traduzido e a imagem do motor de tradução executando-o. No Kubernetes, cada trabalho fixa o digest exato da imagem da réplica web que o agendou. Os trabalhos sobrevivem aos lançamentos web e nunca trocam código a meio caminho de uma tradução. Um trabalho agendado pouco antes de um lançamento pode, portanto, terminar no motor anterior mesmo após o aplicativo web ter sido atualizado. Os detalhes da sessão mostram o digest do motor; sessões mais antigas sem este registro de proveniência exibem “Não registrado.”

A cada cinco minutos, o Glossia verifica se sua Implantação foi totalmente lançada. Apenas um worker desse lançamento saudável pode agendar a recuperação do motor. Se a última sessão de um projeto foi agendada antes que esse lançamento terminasse, rodou em um digest do motor antigo registrado e falhou em seguida dentro das últimas seis horas, o Glossia pode criar uma continuação no lançamento atual. O uso do tempo de fila também cobre trabalhos que esperam por capacidade e só são iniciados após o lançamento. Um digest de imagem diferente por si só não aciona reexecuções de falhas comuns após implantações não relacionadas. Arquivos concluídos e a pull request de tradução aberta são mantidos; apenas o trabalho inacabado é traduzido novamente. Continuidades de lançamento em fila esperam enquanto um lançamento está em progresso, por no máximo 15 minutos. Falhas da API Kubernetes ou de permissão param o lançamento com um erro explícito em vez de serem interpretadas como um lançamento em andamento.

A recuperação é deliberadamente restrita: a sessão deve ter terminado com uma falha de validação de item registrada, e cada item falhado em sua última tentativa deve relatar uma falha de estrutura de Markdown, conteúdo preservado ou falha de unidade de Markdown. Tentativas interrompidas ou parcialmente canceladas não se qualificam. Erros do Provedor, crédito esgotado, credenciais rejeitadas, falhas de publicação, erros de leitura da fonte, falhas de comando de validação externa e causas desconhecidas não são reenviados por uma implantação. Sessões bem-sucedidas, ativas, canceladas, suprimidas e sem versão também são deixadas em paz. Uma sessão mais recente sempre vence, mesmo se o usuário a cancelou.

Uma sessão recebe no máximo uma continuação em um lançamento de motor diferente, com no máximo três continuações de lançamento em uma linhagem. Se o motor novo ainda falhar, não é reenviado novamente na mesma imagem, incluindo após um rollback. A linhagem mantém seus digests de motor tentados anteriormente e o lançador verifica-os novamente antes de criar um trabalho em fila. Limites de recuperação existentes do Provedor são preservados ao longo das continuações de lançamento. Tags de imagem mutáveis e implantações sem uma identidade de lançamento configurada não habilitam a recuperação automática do motor.

## Progresso Durável

Arquivos concluídos e seus lockfiles são publicados no ramo de tradução em lotes: um commit para cada 25 arquivos, ou a cada 15 minutos, e um commit final quando a execução termina. Cada push executa as verificações de pull request do repositório, de modo que o agrupamento evita que uma execução grande inicie uma verificação individual por arquivo. Um projeto possui uma única pull request de tradução: um novo commit no ramo padrão continua a aberta e traduz apenas o que mudou desde então. Assim que essa pull request é integrada ou fechada, a próxima execução inicia uma nova. Dentro dos arquivos inacabados, segmentos validados localmente e lotes de recuperação são também salvos no banco de dados por sete dias. Esses pontos de verificação sobrevivem a uma parada do processo do worker. Eles são delimitados à conta, ao projeto, à entrada do documento, à credencial e ao modelo efetivos, ao contexto e à tentativa de segmento ou reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda coincidem. Ela sempre valida novamente o documento final montado. Respostas do modelo rejeitadas não são pontos de verificação. Uma falha de validação no nível do documento inicia uma tentativa de reparo separada porque o validador pode não identificar um segmento responsável único.

Pontos de verificação expirados e registros de ritmo do provedor inativos são removidos pelo worker de recuperação de sessão agendada. Estes são registros operacionais; os usuários não precisam adicioná-los ao repositório ou configurá-los em `L10N.md`.
