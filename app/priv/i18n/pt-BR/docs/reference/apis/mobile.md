%{
  title: "API do aplicativo móvel e do companheiro",
  summary: "Aparência nativa, perfil, atividade de tradução, análises e conversas privadas Toki.",
  category: "Referência",
  subcategory: "APIs",
  order: 4
}
---

Todos os pontos finais, exceto o catálogo de aparência nativa público, exigem um token de portador. A [Especificação OpenAPI](/api/openapi.json) descreve os esquemas completos. Obtenha tokens através do fluxo [OAuth PKCE](/docs/reference/apis/authentication) existente. Nunca embuti uma chave de provedor de inferência em um cliente.

## Autorização

| Ponto final | Escopo do token |
|---|---|
| `GET /api/native/themes` | Nenhuma (metadados de aparência pública) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Os escopos de token são um limite, não uma concessão. Cada ponto final de projeto também verifica a permissão de leitura do projeto do usuário. Um segundo `project:read` **token** de escopo não é necessário, mas uma associação em uma organização com permissões explícitas deve permitir leituras de projetos e a capacidade solicitada. Novas associações incluem essas capacidades nativas; associações explícitas existentes não são automaticamente ampliadas.

Projetos pessoais seguem as regras de associação pessoal-organização existentes. A visibilidade da conta controla leituras públicas de projetos; um estranho autenticado com o escopo necessário pode ler a atividade de tradução e análises de um projeto público. Gravações Toki exigem associação em conta, portanto a visibilidade pública sozinha não gasta créditos de inferência da conta. Conversas Toki permanecem privadas para o usuário que as criou dentro do projeto, mesmo em contas públicas. Administradores de organização e plataforma não podem ler a conversa de outro usuário. Conhecer um UUID de conversão não concede acesso.

## Aparência nativa

`GET /api/native/themes` metadados de aparência em toda a instância do servidor Glossia selecionado, sem autenticação ou dados de usuário/projeto. Respostas incluem `Cache-Control: public, max-age=300`. Isso não altera a autorização para nenhum ponto final de projeto.

A resposta possui quatro campos obrigatórios:

| Campo | Valor |
|---|---|
| `schema_version` | Inteiro `1` |
| `revision` | Revisão de conteúdo não em branco, no máximo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array contendo o tema padrão Glossia |

O tema padrão possui `id: "glossia"`, `name: "Glossia"`, uma descrição não em branco `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, `light` e paletas de `dark`. Raídeos são pixels lógicos numéricos. Cada paleta contém todos os nove campos abaixo, expressos como cores opacas `#RRGGBB`:

| Campo de paleta | Claro | Escuro |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

O catalog é compilado dos tokens de raídeos e cor canônicos `:root` em `app/priv/static/assets/styles.css`. A paleta escura usa tokens semânticos somente-nativos e não altera o renderização web. Recriar após a mudança de tokens atualiza o catálogo e sua revisão determinística. A revisão cobre o conteúdo do catálogo, não edições do folha de estilo não relacionadas. Não são incluídas preferências por usuário ou configuração do tema em tempo de execução.

## Perfil

`GET /api/me` retorna apenas o perfil do usuário autenticado:

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` pode ser `null`. A alça pertence à conta pessoal do usuário, não à organização selecionada. `server_version` é a versão da aplicação em execução.

## Paginação

As listas de tradução e conversa aceitam `page` (padrão `1`, intervalo `1–10000`) e `page_size` (padrão `20`, intervalo `1–50`). Valores inválidos retornam `400` em vez de silenciosamente limitar. Metadados usam a mesma forma que outras listas da API Glossia:

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

Listas refletem o estado atual, não um instantâneo congelado. A ordem das conversas é baseada na atualização mais recente primeiro, com UUID como o desempate determinístico.

## Atividade de tradução

`GET /api/:handle/projects/:project/translations?page=1` retorna:

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

Statuses são `pending`, `running`, `completed`, `failed`, ou `cancelled`. Mensagem de commit, idioma de origem e sumário podem ser `null` enquanto o trabalho está pendente ou quando indisponível. Resultados são os mais recentes primeiro e restritos ao projeto endereçado.

`GET /api/:handle/projects/:project/translations/:id` retorna `{session: {...}, progress: {...}}`. O `session` possui exatamente os campos de sessão de lista mais `commit_sha`, não alterados. `progress` é reconstruído a partir de eventos duráveis usando o mesmo redutor de progresso Elixir do painel web. Isso é uma consulta direta e exata de UUID dentro do projeto e conta endereçados, independente da paginção ou idade da sessão. IDs malformados, faltante e de projeto estrangeiro retornam `404` com `error: "not_found"`; autenticação e autorização de projeto ainda rodam primeiro (`401`/`403`). Abrir esse recurso nunca cria uma conversa, envia uma mensagem ou inicia inferência. Fornece **procedência de nível de sessão-sumário** e progresso por arquivo, não texto de segmento traduzido ou revisão de saída traduzida.

### Progresso nativo ao vivo

Abra um Socket WebSocket Phoenix persistente em `/native/socket/websocket?vsn=2.0.0` (`wss` em servidores HTTPS). Longpoll está desabilitado. Envie o token de acesso apenas através do cabeçalho do subprotocolo WebSocket, nunca através de parâmetros de consulta:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

O servidor negocia `phoenix`. Assuma o tópico `translation:<session UUID>` com `{"organization":"account-handle","project":"project-handle"}`. O valor da organização é o mesmo alça de conta usada pela API HTTP, incluindo contas pessoais. A resposta de ligação e cada evento `snapshot` carregam a mesma projeção completa que o detalhe HTTP:

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` é a sequência de progresso durável, **não** uma versão de instantâneo única. Mudanças de status/publicação da sessão e contagens de chamada de modelo ao vivo podem produzir um novo instantâneo com a mesma sequência; substitua a projeção anterior mesmo quando `seq` não se alterou. Status por arquivo são `queued`, `running`, `done`, `failed` e `cancelled`. Caminhos, locações e referências de arquivo podem ser `null` antes de serem conhecidos. Uma sessão intocada tem sequência zero, itens vazios e contagens zero. O sumário cobre **todos** os arquivos, mesmo quando itens são omitidos. Os identificadores/contadores de glossário do sumário são a agregação do redutor web, não metadados do provedor.

No máximo 500 itens na ordem de índice planejado são incluídos, com um orçamento combinado de item codificado de 512.000 bytes. Um item que não cabe é omitido e `omitted_items` conta cada linha excluída por qualquer limite. Saída traduzida bruta, texto de streaming, pensamento, cargas privadas do provedor e detalhes de falha brutos são nunca incluídos. Contagens públicas de chamada de modelo ao vivo podem resetar após reconstrução ou reconciliação; contagens finais duras e estados de arquivo são reconstruídos. Instantâneos nativos completos são limitados a 1.000.000 bytes de JSON codificado. Se metadados inalterados da sessão ou o sumário completo sozinho exceder esse limite, a ligação falha com `{"reason":"payload_too_large"}`, ou um canal existente recebe `error` com essa razão e fecha, em vez de enviar um quadro sobrebyte ou trunco silencioso da procedência.

O servidor se inscreve no PubSub de sessão transversal existente **antes de** ler o prefixo durável, dobra a cauda ao vivo com deduplicação de sequência e consolida as notificações de progresso/status/publicação em instantâneos completos a cerca de 100 ms. Não é necessário polling HTTP por cliente ou estado local do runner. A cada cinco segundos, renova a autorização e reconstrói o estado durável para reparar as notificações perdidas. Reconecte e reentre após foregrounding ou interrupção de transporte; a projeção de ligação é suficiente sem reproduzir deltas. Siga o ciclo de vida normal da heartbeat de Phoenix enquanto conectado e deixe o tópico quando não estiver mais visualizando-o.

O token persistente atual, caducidade/anulação, usuário, `translation:read` escopo de token, permissões de política, visibilidade de projeto e associação exata de conta/projeto/sessão são verificados na ligação e antes de cada instantâneo. Falta de escopo ou permissão de política retorna `{"reason":"forbidden"}`; recurso ausente retorna `{"reason":"not_found"}`; autenticação expirada/anulada retorna `{"reason":"sign_in_required"}`. Após uma ligação bem-sucedida, negação emite `access_revoked` com essa razão e fecha imediatamente o canal sem outro instantâneo. A renovação também detecta anulação em canais inativos. Em `sign_in_required`, atualize/re-autentique e crie uma nova conexão; em outras negações, pare de exibir o detalhe protegido. WebSockets são um mecanismo de atualização ao vivo em primeiro plano, não uma garantia de entrega enquanto o aplicativo móvel está suspenso.

## Análises

`GET /api/:handle/projects/:project/analytics?days=30` retorna métricas resumidas, até dez páginas mais acessadas e a série temporal de tráfego. Um projeto vazio retorna:

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` padrão é `30` e deve ser um inteiro de `1` a `365`. A janela de relatórios UTC rolante termina no momento do pedido. Estes são os mesmos agregados escopados de projeto do ClickHouse que o painel, incluindo seus identificadores de visitante rodados diariamente. Falhas de armazenamento retornam `503` com `error: "analytics_unavailable"`, nunca métricas zero inventadas.

`traffic.granularity` é `"hour"` para janelas de até dois dias, `"day"` para janelas de até noventa dias e `"month"` caso contrário. `traffic.points` é cronológico. Cada ponto contém um timestamp de início de bucket UTC e contagens inteiras não negativas:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Contagens incluem apenas eventos na janela de relatórios solicitada, para que os primeiros e últimos buckets possam ser parciais. Quando eventos existem, buckets calmos nessa janela são incluídos com contagens zero. Quando nenhum evento existe, `points` está vazio em vez de uma tendência plana sintética. `unique_visitors` conta identificadores distintos **dentro de cada bucket**; somando esses valores não fornece a contagem de visitantes distintos do período. Use `summary.unique_visitors` para esse total. Os clientes devem plotar os buckets retornados inalterados em vez de reconstruir uma tendência a partir de métricas resumidas.

## Conversas Toki

### Criar e listar

`POST /api/:handle/projects/:project/toki/conversations` aceita um UUID gerado pelo cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Retorna `201` com `{conversation, messages: []}`. Conversas vazias têm título `New conversation` e status `completed` (inativo, não gerando). Reproduzindo o mesmo UUID para o mesmo ator, projeto e origem retorna o detalhe existente sem criar outra conversa. Reutilizando para outro ator, projeto ou origem retorna `409` com `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retorna `{conversations: [...], meta: {...}}`. Uma conversa contém `id`, `title`, `status`, `updated_at`, `error` opcional e `translation_session_id` opcional. Títulos são derivados da primeira mensagem do usuário, não de uma segunda chamada de modelo.

### Origem de tradução

A criação opcionalmente aceita um UUID de sessão de tradução do mesmo projeto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

A origem é imutável; omissão e `null` significam sem origem. Uma repetição deve fornecer a mesma origem, incluindo após enviar mensagens. Não pode anexar uma origem posteriormente ou removê-la com uma repetição. Uma origem malformada retorna `422`; uma fonte ausente ou de projeto estrangeiro retorna `404`. A criação vinculada à origem adicionalmente requer `translation:read` escopo de token e permissão de política atual, junto com `toki:write` e permissão de leitura do projeto. Resumos de origem fornecidos pelo cliente, metadata, papéis e propriedade são ignorados. Apenas o UUID é persistido; o servidor resolve seu contexto autorizado no momento da resposta.

**Conversas vinculadas à origem falham fechadas**, em vez de meramente censurar o UUID: sem escopo `translation:read` atual ou permissão de política, detalhes, repetição de criação com origem correspondente, envio de mensagem e reprodução de mensagem retornam `403`. Uma origem incompatível ainda retorna `409` sem retornar histórico ou metadata da origem. Listas omitem a conversa inteira vinculada à origem, incluindo seu título e contribuição para contagens de paginação. Isso protege mensagens anteriores do assistente que podem mencionar a fonte. Escopos ausentes incluem o desafio normal `WWW-Authenticate`. Conversas não vinculadas mantêm seu comportamento existente de autorização apenas Toki.

Fontes excluídas ou movidas também falham fechadas: detalhes vinculados à origem, envios e novas repetições de criação retornam `404`, e as listas omitem a conversa. O UUID imutável permanece após a exclusão da fonte para que uma repetição não possa silenciosamente se tornar não vinculada. A referência não tem uma chave estrangeira em cascata; cada uso verifica a existência atual da fonte e seu projeto/conta exato. Nenhuma referência de origem confere acesso ou muda uma voz, glossário ou contexto compartilhado.

Criar ou abrir uma conversa vinculada à origem **não** envia uma mensagem ou enfileira inferências. A navegação nativa deve buscar o detalhe de tradução primeiro; apenas uma ação explícita do usuário deve criar a conversa, e uma submissão de mensagem explícita separada inicia um turno. Nenhuma publicação de proposta, revisão de discussão compartilhada ou ferramentas de escrita de agente são fornecidas.

### Enviar e consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` aceita um UUID de **mensagem** gerado separadamente pelo cliente:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

O pedido persiste a mensagem do usuário e um job Oban em uma única transação de banco de dados. Não chama um modelo. Retorna `202` com status da conversa `queued` e as mensagens atuais. Consulte `GET /api/:handle/projects/:project/toki/conversations/:id` enquanto o status é `queued` ou `running`; pare em `completed` ou `failed`.

Respostas detalhadas têm este formato:

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

Mensagens têm papel `user` ou `assistant` e são cronológicas. Uma conversa mantém no máximo 100 mensagens, para que o endpoint de detalhes retorne todo seu histórico limitado sem um pedido adicional de página.

Repetir um UUID de mensagem com conteúdo idêntico nunca enfileira outra inferência, incluindo após conclusão ou falha. Uma repetição finalizada retorna `200`; uma repetição pendente retorna `202`. Reutilizar um UUID com conteúdo diferente ou em outra conversa retorna `409`. Uma mensagem diferente enviada enquanto um turno está ativo retorna `409` com `error: "conversation_busy"`.

### Comportamento e limitações do modelo

- Cada mensagem de usuário é texto não vazio, no máximo 8.000 caracteres e 32.000 bytes UTF-8. UUIDs inválidos, tipos ou conteúdos retornam `422`.
- Cada usuário pode manter no máximo 100 conversas por projeto e cinco conversas em fila/executando entre projetos. Mais de cinco turnos pendentes retornam `429`; limites de conversa/histórico retornam `422`.
- Novas mensagens são limitadas a 30 por hora por usuário e por servidor, além das limitações de taxa de API normais. Repetições não consomem cota de inferência.
- A fila Oban dedicada executa duas tarefas concorrentemente por servidor. Cada turno realiza, no máximo, uma requisição HTTP do provedor: ReqLLM prepara a requisição do provedor, e o trabalhador Oban executa-a sincronamente com tentativas HTTP de reenvio e redirecionamentos desativados após a anexação do provedor. Nenhuma sessão Condukt, tarefa de inferência desacoplada, ferramentas, subagentes ou carregamento de instruções do sistema de arquivos está envolvido. O provedor recebe um teto de 2.048 tokens de saída; as respostas do assistente também são limitadas a 8.000 caracteres e 32.000 bytes.
- Aguardas de conexão e de pool HTTP são limitadas a cinco segundos e aguardas de recebimento de soquete a sessenta segundos. O trabalhador Oban tem um prazo rígido de 90 segundos no relógio de parede, incluindo respostas recebidas progressivamente. A terminação do trabalhador também termina sua execução local de inferência. Desconectar não pode garantir a anulação de computação já aceita por um provedor remoto, por isso falhas ambíguas nunca são repetidas automaticamente.
- O modelo recebe metadados do projeto limitados e até três resumos recentes de tradução quando tanto o token quanto a associação atual permitem `translation:read`. Os últimos dez trechos de conversa são limitados independentemente do armazenamento. Ele não possui capacidades de escrita ou acesso geral ao repositório, e nenhuma analítica é fornecida ao modelo.
- Para uma conversa vinculada à origem, o modelo recebe adicionalmente a fonte persistente exata, mesmo que não seja recente: UUID, status, metadados de commit, idiomas, contagem e, no máximo, 1.000 caracteres de resumo. O contexto está etiquetado `provenance: "session_summary"` e o prompt exige relatar essa limitação de nível de resumo. Nenhum texto de segmento, arquivos de repositório ou contexto de origem fornecido pelo cliente é carregado.
- Credenciais resolvem-se através do modelo gerativo existente da conta e da configuração de inferência do servidor. Sessões interativas de CLI/OAuth não são utilizadas para o Toki. Credenciais ausentes ou não suportadas produzem status `failed` com `error: "provider_unavailable"`.
- Falhas do provedor produzem `inference_failed`; saída vazia ou com tamanho excessivo produz `invalid_provider_response`. Erros brutos do provedor e segredos não são retornados. Nenhuma resposta sintética do assistente é inserida em caso de falha.
- Acesso ao projeto/conta e existência da fonte, associação projeto/conta e autorização de tradução são novamente verificados antes e após a inferência. Acesso revogado ou escopos em fila insuficientes falham o turno com `not_authorized`; uma fonte excluída ou movida falha com `source_unavailable`. Nenhuma resposta do assistente é persistida em qualquer falha.
- Uma tarefa de recuperação roda a cada minuto e marca trabalhos em execução mais antigos que dois minutos ou trabalhos em fila mais antigos que quinze minutos como `failed` com `inference_interrupted`. Isso normaliza tarefas com tempo esgotado, terminadas e órfãs sem repetição da inferência. Uma tarefa atrasada não pode reivindicar uma mensagem expirada ou sobrescrever um turno mais recente. Um usuário pode intencionalmente enviar um **novo** UUID de mensagem após uma falha.

## Erros

`401` significa falha na autenticação. `403` significa que o escopo ou política de recursos negou acesso; escopos ausentes incluem um desafio `WWW-Authenticate`. Projetos desconhecidos e UUIDs de conversas estrangeiras/privadas retornam `404`. Validação usa `422`, paginação usa `400`, conflitos UUID/ocupados usam `409` e exaurição de cota usa `429`.
