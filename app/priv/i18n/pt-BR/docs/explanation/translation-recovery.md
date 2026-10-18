%{
  title: "Recuperação de tradução",
  summary:
    "Como o Glossia mantém o Markdown intacto e se recupera da limitação de taxa do provedor e de traduções interrompidas.",
  category: "explicação",
  section: "translation",
  order: 8
}
---

O Glossia valida o conteúdo traduzido antes de publicá-lo. A recuperação preserva esse requisito: uma nova tentativa ainda deve preservar a estrutura da fonte e os placeholders necessários, e todo arquivo montado passa em seus comandos de validação configurados.

## Tradução Markdown

O Glossia nunca regenera um documento de Markdown traduzido. Ele analisa a fonte apenas para encontrar sua prose: parágrafos, cabeçalhos, itens de lista, células de tabela, os atributos voltados ao leitor de componentes e HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), e o texto de um HTML `<summary>`. Cada tradução é escrita de volta nos bytes exatos que a fonte ocupou, de modo que código, destinos de links, componentes, alertas do GitHub, âncoras explícitas de cabeçalho, como `{#install}`, marcadores de lista e linhas em branco permaneçam idênticos byte a byte.

Cada parágrafo ou cabeçalho é traduzido como uma sentença completa. Formatação em linha transforma-se em tags numeradas: `<gN>...</gN>` ao redor de palavras vinculadas ou enfatizadas, e `<gN/>` para conteúdo que não deve mudar, como código em linha ou um componente. O modelo pode mover tags para seguir a ordem das palavras da língua-alvo, mas deve manter cada tag exatamente uma vez. Toda solicitação também carrega o documento fonte circundante e as traduções mais recentes do mesmo arquivo, para referência.

Uma unidade que perde ou inventa uma tag é enviada novamente por conta própria, com o motivo, no máximo três vezes. Unidades que retornaram válidas são mantidas. Após o splicing, o Glossia analisa o resultado e compara sua estrutura com a fonte. Uma tradução que se tornaria um cabeçalho, lista, ou ênfase por si só ter sua prose escapeada, o que não requer mais chamada de modelo.

## Tradução de catálogo

Os catálogos Gettext são analisados em strings antes da tradução. As solicitações carregam no máximo oito strings, com um alvo de lotes de 8.000 bytes. Uma string maior permanece intacta. O modelo retorna um array com o mesmo número de strings na mesma ordem. O Glossia verifica variáveis de interpolação e rejeita traduções vazias.

Os cabeçalhos são construídos em código usando as regras de plural da localidade de destino. Identificadores de mensagem da fonte, comentários e estrutura de catálogo provêm da fonte analisada. Se um lote retornar conteúdo malformatado, o Glossia o reenvia uma vez, e então o divide em lotes menores. Lotes vizinhos bem-sucedidos não precisam ser traduzidos novamente.

## Limitação de taxa do provedor

O Glossia coordena solicitações de tradução que usam a mesma credencial e modelo. Uma resposta de limitação de taxa estende seu cooldown compartilhado e aumenta o espaçamento entre novas solicitações. O tráfego bem-sucedido reduz gradualmente esse espaçamento após um minuto sem throttling. Solicitações já em execução são permitidas a terminar.

As dicas de tentativa de repetição do provedor são atrasos mínimos. Falhas repetidas também aumentam o backoff, até um atraso de base de 30 segundos mais jitter; uma dica de provedor mais longa tem precedência, limitada a cinco minutos. O cabeçalho `x-ratelimit-reset` do Together é reconhecido ao lado de `retry-after`.

Após oito tentativas de solicitação sem sucesso, a execução do repositório para de iniciar novos arquivos. Uma continuação adiada herdada do ramo de tradução e resume seu trabalho inacabado. A tentativa anterior permanece visível no histórico da sessão, vinculada através da continuação. Atrasos aumentam de um minuto para cinco minutos, no máximo seis continuações automáticas. Sessões ativas mais recentes têm precedência, e sessões canceladas nunca são reativadas. Falhas de validação sozinhas não agendam a recuperação do provedor.

## Progresso durável

Arquivos concluídos e seus lockfiles são publicados no ramo de tradução em lotes: um commit para cada 25 arquivos, ou a cada 15 minutos, e um commit final quando a execução termina. Cada push executa os testes de pull request do repositório, de modo que o agrupamento impede que uma execução grande comece uma execução de verificação por arquivo. Um projeto tem um único pull request de tradução: um novo commit na branch padrão continua o que está aberto, e apenas traduz o que mudou desde então. Assim que esse pull request é mesclado ou fechado, a próxima execução inicia um novo. Dentro de arquivos inacabados, segmentos validados localmente e lotes de recuperação também são salvos no banco de dados por sete dias. Esses checkpoints sobrevivem a uma parada de processo de trabalho. São escopados para a conta, projeto, entrada do documento, credencial e modelo efetivos, contexto, e segmento ou tentativa de reparo.

Uma execução retomada pode reutilizar um segmento apenas quando suas entradas ainda correspondem. Ela sempre valida o documento final montado novamente. Respostas do modelo rejeitadas não são checkpoints. Uma falha de validação em nível de documento inicia uma tentativa de reparo separada porque o validador pode não identificar um segmento responsável único.

Checkpoints expirados e registros de ritmo do provedor inativos são removidos pelo trabalhador agendado de recuperação de sessão. São registros operacionais; os usuários não precisam adicioná-los ao seu repositório ou configurá-los em `L10N.md`.
