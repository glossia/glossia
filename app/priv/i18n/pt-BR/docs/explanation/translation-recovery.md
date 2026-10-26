%{
  title: "Recuperação de tradução",
  summary:
    "Como o Glossia mantém o Markdown inalterado e se recupera de limitações do provedor e traduções interrompidas.",
  category: "explicação",
  section: "translation",
  order: 8
}
---

O Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva esse requisito: uma nova tentativa deve ainda preservar a estrutura da fonte e os placeholders obrigatórios, e cada arquivo montado passa por seus comandos de validação configurados.

## Tradução para Markdown

O Glossia nunca re-rende riz um documento Markdown traduzido. Ele analisa a fonte apenas para encontrar a prosa: parágrafos, cabeçalhos, itens de lista, células de tabela, os atributos voltados ao leitor de componentes e HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`) e o texto de um elemento `<summary>` HTML. Cada tradução é devolvida para os exatos bytes que a fonte ocupou, portanto código, destinos de links, componentes, alertas GitHub, âncoras de cabeçalho explícitas como `{#install}`, marcadores de lista e linhas em branco permanecem idênticos byte a byte.

Cada parágrafo ou cabeçalho é traduzido como uma sentença completa. Formatação em linha vira tags numeradas: `<gN>...</gN>` ao redor de palavras com links ou em destaque, e `<gN/>` para conteúdo que não pode mudar, como código em linha ou um componente. O modelo pode mover tags para seguir a ordem de palavras do idioma-alvo, mas deve manter cada tag exatamente uma vez. Todo pedido também carrega o documento fonte circundante e as traduções mais recentes do mesmo arquivo, para referência.

Uma unidade que perde ou cria uma tag é enviada novamente por si mesma, com o motivo, até três vezes. Unidades que voltaram válidas são mantidas. Após a costura, o Glossia analisa o resultado e compara sua estrutura com a fonte. Uma tradução que se tornaria um cabeçalho, lista ou destaque sozinha tem sua prosa escapada, o que exige nenhuma chamada de modelo adicional.

## Tradução de catálogos

Catálogos do Gettext são analisados em strings antes da tradução. Pedidos levam até oito strings, com um alvo de agrupamento de 8.000 bytes. Uma string maior sozinha permanece intacta. O modelo devolve um array com a mesma quantidade de strings na mesma ordem. O Glossia verifica variáveis de interpolação e rejeita traduções vazias.

Cabeçalhos são construídos em código usando as regras de plural da locale-alvo. Identificadores de mensagens da fonte, comentários e estrutura do catálogo vêm da fonte analisada. Se um pedido devolve conteúdo malformado, o Glossio o reenvia uma vez, depois o divide em pedidos menores. Pedidos vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Gargalo de provedor

O Glossia coordena pedidos de tradução que usam o mesmo credencial e modelo. Uma resposta de limite de taxa estende sua cooldown compartilhada e aumenta o espaçamento entre novos pedidos. Tráfego bem-sucedido gradualmente reduz esse espaçamento depois de um minuto sem gargalo. Pedidos já em execução são permitidos para terminar.

Dicas de retorno do provedor são atrasos mínimos. Falhas repetidas também aumentam o backoff, até um atraso base de 30 segundos mais jitter; uma dica de provedor mais longa tem precedência, limitada a cinco minutos. O cabeçalho Together `x-ratelimit-reset` é reconhecido ao lado de `retry-after`.

Após oito tentativas de pedido não-sucedidas, a execução do repositório para de iniciar novos arquivos. Uma continuação atrasada herda a branch de tradução e retoma seu trabalho inacabado. A tentativa anterior permanece visível na história de sessão, linkada através da continuação. Atrasos aumentam de um minuto para cinco minutos, com no máximo seis continuации automáticas. Sessões mais recentes têm precedência, e sessões canceladas nunca são ressuscitadas. Falhas de validação sozinhas não agendaram recuperação do provedor.

## Recuperação após uma versão de motor

Uma sessão tem duas versões independentes: o compromisso de repositório sendo traduzido e a imagem do motor de tradução executando-o. No Kubernetes, cada tarefas fixa o digest exato da imagem do réplica web que agendou-a. Tarefas sobrevivem rotas web e nunca mudam código ao meio-percurso de uma tradução. Uma tarefa agendada logo antes de uma rota pode portanto terminar no motor anterior mesmo depois de a aplicação web ter atualizado. Os detalhes da sessão mostram o digest do motor; sessões antigas sem essa procedência exibem "Não gravado."

A cada cinco minutos, o Glossia verifica se sua implantação foi totalmente roletada. Apenas um trabalhador dessa lançamento saudável pode agendar recuperação do motor. Se a sessão mais recente de um projeto foi enfileirada antes que essa roleta terminasse, rodou em um digest do motor mais antigo gravado, e falhou depoisward dentro das últimas seis horas, o Glossia pode criar uma continuação na versão atual. Usando tempo de fila também cobre tarefas que esperam capacidade e só bootam após a roleta. Apenas um digest diferente de imagem não gatilha re-tentativas de falhas comuns após implantações não relacionadas. Arquivos concluídos e o pull request de tradução aberto levam adiante; apenas trabalho inacabado é traduzido novamente. Continuẩdos de versão em fila esperam enquanto uma roleta está em进展, por no máximo 15 minutos. Falhas de API Kubernetes ou de permissão param o lançamento com um erro explícito ao em vez de serem confundidos por uma roleta em progressão.

Reeperação é intencionalmente estreita: a sessão deve ter terminado com uma falha de validação de item gravada, e todo item falhado em sua última tentativa deve relatar uma falha de estrutura Markdown, conteúdo preservado, ou unidade Markdown. Tentativas interrompidas ou parcialmente canceladas não qualificam. Erros de provedor, crédito exausto, credenciais rejeitadas, falhas de publicação, erros de leitura fonte, falhas de comando de validação externas, e causas desconhecidas não são reenviadas por uma implantação. Sessões bem-sucedidas, ativas, canceladas, anuladas, e sem versão também são deixadas sozinhas. Uma sessão mais recente sempre vence, mesmo se o usuário a cancelou.

Uma sessão obtém no máximo uma continuação em uma versão de motor diferente, com no máximo três continuărições de versão em uma linhagem. Se o novo motor ainda falha, não é reenviado novamente em aquela imagem, incluindo após um rollback. A linhagem mantém seus digestos de motor tentados previamente, e o lançador os verifica novamente antes de criar uma tarefa enfileirada. Limites existentes de recuperação de provedor são preservados ao longo de continuăriões de versão. Tags de imagem mutáveis e implantações sem uma identidade de versão configurada não habilitam recuperação automática de motor.

## Progresso duradouro

Arquivos concluídos e seus lockfiles são publicados à branch de tradução em lotes: um commit para cada 25 arquivos, ou a cada 15 minutos, e um commit final quando a execução termina. Cada push executa as verificações de pull request do repositório, de modo que o agrupamento impede que uma grande execução inicie uma única execução de verificação por arquivo. Um projeto tem um único pull request de tradução: um novo commit na branch padrão continua o aberto e traduz apenas o que mudou desde então. Uma vez que esse pull request é fundido ou fechado, a próxima execução inicia uma nova. Dentro dos arquivos inacabados, segmentos validados localmente e lotes de recuperação também são salvos no banco de dados por sete dias. Esses checkpoints sobrevivem a uma parada do processo worker. Eles são limitados ao nível da conta, projeto, entrada do documento, credencial e modelo efetivos, contexto, e tentativa de segmento ou reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda correspondem. Ela sempre valida novamente o documento final montado. Respostas do modelo rejeitadas não são checkpoints. Uma falha de validação no nível do documento inicia uma tentativa de reparo separada, porque o validador pode não identificar um único segmento responsável.

Checkpoint expirados e registros de ritmo do provedor inativos são removidos pelo worker de recuperação de sessão agendado. Estes são registros operacionais; os usuários não precisam adicioná-los ao seu repositório ou configurá-los em `L10N.md`.
