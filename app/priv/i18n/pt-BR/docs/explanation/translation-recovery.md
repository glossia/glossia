%{
  title: "Recuperação de tradução",
  summary: "Como a Glossia se recupera da limitação do provedor e traduções interrompidas.",
  category: "explicação",
  order: 8
}
---
Glossia valida o conteúdo traduzido antes de publicá-lo. Recuperação preserva
esse requisito: uma nova tentativa deve ainda preservar a estrutura da origem e os
marcadores de substituição, e cada arquivo montado passa em seus comandos de validação configurados.

## Tradução de catálogos

Os catálogos Gettext são processados em strings antes da tradução. As requisições carregam até
no máximo oito strings, com um objetivo de agrupamento de 8.000 bytes. Uma string individual maior
permanece intacta. O modelo retorna um array com o mesmo número de strings na
mesma ordem. Glossia verifica variáveis de interpolação e rejeita traduções vazias.

Cabeçalhos são construídos no código usando as regras de plural do locale de destino. Mensagem de origem
identificadores, comentários e estrutura do catálogo provêm da fonte analisada. Se um
batch retorna conteúdo malformatado, Glossia o reenvia uma vez, em seguida, divide-o em
lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Throttling do provedor

Trabalhadores que usam a mesma credencial e modelo compartilham a admissão de requisições através do
banco de dados, incluindo trabalhadores em réplicas diferentes do aplicativo. Um limite de taxa
resposta estende o cooldown compartilhado deles e aumenta o espaçamento entre novas requisições.
O tráfego bem-sucedido reduz gradualmente esse intervalo após um minuto sem limitação.
Solicitações já em andamento são permitidas para concluir.

As indicações de reintentiva do provedor são atrasos mínimos. Falhas repetidas também aumentam o
backoff, até um atraso base de 30 segundos mais jitter; uma dica de provedor mais longa assume
precedência, limitada a cinco minutos. Do Together `x-ratelimit-reset` cabeçalho é
reconhecido junto com `retry-after`.

Após oito tentativas de requisição sem sucesso, a execução do repositório para de iniciar novas
arquivos. Uma continuação adiada herda o ramo de tradução e retoma sua
trabalho inacabado. A tentativa anterior permanece visível no histórico de sessão, vinculada
através da continuação. Os atrasos aumentam de um minuto para cinco minutos, com
no máximo seis continuações automáticas. Sessões ativas mais recentes têm precedência, e
sessões canceladas nunca são revividas. Falhas de validação sozinhas não agendam
recuperação do provedor.

## Progresso durável

Arquivos concluídos e seus arquivos de bloqueio são publicados na branch de tradução como
antes. Dentro de arquivos não concluídos, segmentos validados localmente e lotes de recuperação
são também salvos no banco de dados por sete dias. Esses pontos de controle sobrevivem a um worker
processo parando. Eles são limitados à conta, projeto, entrada do documento,
credencial efetiva e modelo, contexto e tentativa de segmento ou reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda correspondem. Ela sempre
valida o documento final montado novamente. Respostas do modelo rejeitadas não
são pontos de controle. Uma falha de validação no nível do documento inicia uma tentativa de reparo separada.
porque o validador pode não identificar um segmento responsável único.

Pontos de verificação expirados e registros de ritmo inativos do provedor são removidos pelo
trabalhador de recuperação de sessão agendada. Estes são registros operacionais; os usuários não
precisam adicioná-los ao seu repositório ou configurá-los em `L10N.md`.