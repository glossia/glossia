%{
  title: "Recuperação de tradução",
  summary: "Como o Glossia se recupera da limitação do provedor e de traduções interrompidas.",
  category: "Explicação",
  section: "translation",
  order: 8
}
---
Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva
esse requisito: uma nova tentativa deve ainda preservar a estrutura de origem e os obrigatórios
placeholders, e cada arquivo montado passa pelos seus comandos de validação configurados.

## Tradução de catálogo

Os catálogos Gettext são convertidos em strings antes da tradução. As solicitações carregam até
no máximo oito strings, com um alvo de batching de 8.000 bytes. Uma única string maior
permanece intacta. O modelo retorna um array com o mesmo número de strings na
mesma ordem. A Glossia verifica as variáveis de interpolação e rejeita traduções vazias.

Os cabeçalhos são construídos no código usando as regras de plural do locale de destino. Mensagem da fonte
identificadores, comentários e estrutura de catálogo vêm da fonte analisada. Se um
lote retorna conteúdo malformado, Glossia o reintenta uma vez, em seguida o divide em
lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Limitação do provedor

Glossia coordena solicitações de tradução que usam a mesma credencial e modelo. Um limite de taxa
resposta estende seu período de espera compartilhado e aumenta o intervalo entre novas solicitações.
O tráfego bem-sucedido gradualmente reduz esse intervalo após um minuto sem limitação.
Solicitações já em execução podem terminar.

As dicas de reintento do provedor são atrasos mínimos. Falhas repetidas também aumentam o
backoff, até um atraso base de 30 segundos mais jitter; uma dica de provedor mais longa assume
precedência, limitada a cinco minutos. Do Together `x-ratelimit-reset` cabeçalho é
reconhecido juntamente com `retry-after`.

Após oito tentativas de solicitação sem sucesso, a execução do repositório para de iniciar novas
arquivos. Uma continuação atrasada herda o ramo de tradução e retoma sua
trabalho pendente. A tentativa anterior permanece visível no histórico da sessão, vinculada
através da continuação. Os atrasos aumentam de um minuto para cinco minutos, com
no máximo seis continuação automática. Sessões ativas mais recentes têm prioridade, e
sessões canceladas nunca são restauradas. Falhas de validação sozinhas não agendam
recuperação do provedor.

## Progresso durável

Arquivos concluídos e seus arquivos de bloqueio são publicados ao ramo de tradução como
Antes. Dentro de arquivos inacabados, segmentos validados localmente e lotes de recuperação
também são salvos no banco de dados por sete dias. Estes pontos de controle sobrevivem ao trabalhador
processo de parada. Elas são delimitadas à conta, projeto, entrada do documento,
credencial efetiva e modelo, contexto e segmento ou tentativa de reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda coincidem. Ela sempre
valida novamente o documento final montado. Respostas do modelo rejeitadas não são
pontos de controle. Uma falha na validação de nível de documento inicia uma tentativa de reparo separada
porque o validador pode não identificar um segmento responsável único.

Pontos de verificação expirados e registros de ritmo inativos do provedor são removidos pelo
trabalhador de recuperação de sessão agendada. Estes são registros operacionais; os usuários não
precisam adicioná-los ao repositório ou configurá-los em `L10N.md`.