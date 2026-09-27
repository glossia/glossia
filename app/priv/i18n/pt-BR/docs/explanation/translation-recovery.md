%{
  title: "Recuperação de tradução",
  summary: "Como o Glossia se recupera da limitação do provedor e interrupções de tradução.",
  category: "explicação",
  section: "tradução",
  order: 8
}
---
Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva
a essa exigência: uma nova tentativa deve ainda preservar a estrutura da fonte e os
placeholders necessários, e cada arquivo montado passa por seus comandos de validação configurados.

## Tradução de catálogo

Os catálogos Gettext são interpretados em strings antes da tradução. Os pedidos transportam a
mais oito strings, com um alvo de empacotamento de 8.000 bytes. Uma única string maior
permanece intacta. O modelo retorna um array com o mesmo número de strings no
mesma ordem. A Glossia verifica as variáveis de interpolação e rejeita traduções vazias.

Os cabeçalhos são construídos em código usando as regras de pluralidade do locale de destino. Mensagem de origem
identificadores, comentários e estrutura do catálogo provêm da fonte analisada. Se um
lote retorna conteúdo malformado, Glossia reprocessa-o uma vez e depois o divide em
lotes menores. Lotes vizinhos de sucesso não precisam ser traduzidos novamente.

## Limitação de taxa do provedor

Trabalhadores que usam a mesma credencial e modelo compartilham a admissão de solicitações através do
banco de dados, incluindo trabalhadores em réplicas diferentes de aplicações. Uma limitação de taxa
resposta estende seu período de espera compartilhado e aumenta o intervalo entre novas solicitações.
O tráfego bem-sucedido gradualmente reduz esse intervalo após um minuto sem limitação de taxa.
As requisições já em execução são permitidas a finalizar.

As dicas de retry do provedor são atrasos mínimos. Falhas repetidas também aumentam o
backoff, até um atraso base de 30 segundos mais jitter; uma dica de provedor mais longa tem
precedência, limitada a cinco minutos. do Together `x-ratelimit-reset` cabeçalho é
reconhecido junto com `retry-after`.

Após oito tentativas de requisição sem sucesso, a execução do repositório para de iniciar novos
arquivos. Uma continuação adiada herda o ramo de tradução e retoma o seu
trabalho pendente. A tentativa anterior permanece visível no histórico de sessão, vinculada
através da continuação. Os atrasos aumentam de um para cinco minutos, com
no máximo seis continuações automáticas. Sessões ativas mais recentes têm prioridade, e
sessões canceladas nunca são reativadas. Falhas de validação por si só não agendam
a recuperação do provedor.

## Progresso durável

Arquivos concluídos e seus arquivos de bloqueio são publicados na branch de tradução como
anteriormente. Dentro dos arquivos inacabados, segmentos validados localmente e lotes de recuperação
são também salvos no banco de dados por sete dias. Esses pontos de verificação sobrevivem a um worker
processo parando. Eles estão limitados à conta, projeto, entrada de documento,
credencial vigente e modelo, contexto, e segmento ou tentativa de reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda correspondem. Ela sempre
valida o documento final montado novamente. Respostas de modelo rejeitadas não são
pontos de verificação. Uma falha de validação de nível de documento inicia uma tentativa de reparo separada
porque o validador pode não identificar um segmento responsável único.

Pontos de verificação expirados e registros de ritmo do provedor inativos são removidos pelo
trabalhador de recuperação de sessão agendada. Estes são registros operacionais; usuários não
precisam adicioná-los ao seu repositório ou configurá-los em `L10N.md`.