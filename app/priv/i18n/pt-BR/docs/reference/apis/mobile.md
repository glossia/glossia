%{
  title: "Mobile e API de acompanhamento",
  summary: "Aparência nativa, perfil, atividade de tradução, análises e conversas Toki privadas.",
  category: "referência",
  subcategory: "APIs",
  order: 4
}
---

Todos os endpoints, exceto o catálogo de aparência nativa pública, exigem um token de portador. A [especificação OpenAPI](/api/openapi.json) descreve os esquemas completos. Obtém os tokens através do fluxo existente de [OAuth PKCE](/docs/reference/apis/authentication). Nunca embute uma chave de provedor de inferência em um cliente.

## Autorização

| Endpoint | Escopo do token |
|---|---|
| `GET /api/native/themes` | Nenhum (metadados de aparência pública) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Os escopos de token são um limite, não uma concessão. Cada endpoint de projeto também verifica a permissão de leitura do projeto do usuário. Um segundo escopo `project:read` **token** não é necessário, mas um membro da organização com permissões explícitas deve permitir tanto leituras de projeto quanto a capacidade solicitada. Novas adesões incluem essas capacidades móveis; as adesões explícitas existentes não são automaticamente ampliadas.

Projetos pessoais seguem as regras existentes de adesão da organização pessoal. A visibilidade da conta controla leituras de projeto públicas; um estranho autenticado com o escopo necessário pode ler a atividade de tradução e análises de um projeto público. Gravações do Toki exigem adesão à conta, então apenas a visibilidade pública não gasta créditos de inferência da conta. As conversas do Toki permanecem privadas para o usuário que as criou dentro de seu projeto, mesmo em contas públicas. Administradores de organização e plataforma não podem ler a conversa de outro usuário. Conhecer o UUID de uma conversa não concede acesso.

## Aparência nativa

`GET /api/native/themes` retorna metadados de aparência em nível de instância do Glossia selecionado, sem autenticação ou dados de usuário/projeto. As respostas incluem `Cache-Control: public, max-age=300`. Isso não altera a autorização para nenhum endpoint de projeto.

A resposta possui quatro campos obrigatórios:

| Campo | Valor |
|---|---|
| `schema_version` | Inteiro `1` |
| `revision` | Revisão de conteúdo não em branco, no máximo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array contendo o tema padrão do Glossia |

O tema padrão possui `id: "glossia"`, `name: "Glossia"`, uma `description` não em branco, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` e `light` e `dark` paletas. Os raios são pixels lógicos numéricos. Cada paleta contém todos os nove campos abaixo, expressos como cores `#RRGGBB` opacas:

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

O catálogo é compilado a partir dos `:root` e tokens de raio canônicos em `app/priv/static/assets/styles.css`. A paleta escura usa tokens semânticos exclusivos do nativo e não altera a renderização web. Recriar após uma mudança de token atualiza o catálogo e sua revisão determinística. A revisão cobre o conteúdo do catálogo, não alterações não relacionadas na folha de estilo. Não há preferências por usuário ou configuração de tema em tempo de execução.

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

`name` pode ser `null`. O handle pertence à conta pessoal do usuário, não à organização selecionada. `server_version` é a versão da aplicação em execução.

## Paginação

Listas de tradução e conversa aceitam `page` (padrão `1`, intervalo `1–10000`) e `page_size` (padrão `20`, intervalo `1–50`). Valores inválidos retornam `400` em vez de silenciosamente ajustar.

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

As listas refletem o estado atual, não um snapshot congelado. A ordenação de conversas é a mais recentemente atualizada primeiro, com UUID como desempate determinístico.

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

Os status são `pending`, `running`, `completed`, `failed`, ou `cancelled`. A mensagem de commit, idioma de origem e sumário podem ser `null` enquanto o trabalho está pendente ou indisponível. Os resultados são exibidos primeiro por data mais recente e restritos ao projeto abordado.

`GET /api/:handle/projects/:project/translations/:id` retorna `{session: {...}, progress: {...}}`. O `session` possui exatamente os campos de sessão da lista, mais `commit_sha` opcional, não alterado. `progress` é reconstruído a partir de eventos duráveis usando o mesmo redutor de progresso Elixir quanto o painel web. Isso é uma busca direta e exata de UUID dentro do projeto e conta abordados, independente da paginação ou idade da sessão. Identificadores de sessão malformados, ausentes e de outro projeto retornam `404` com `error: "not_found"`; autenticação e autorização de projeto ainda rodam primeiro (`401`/`403`). Abrir este recurso nunca cria uma conversa, envia uma mensagem ou inicia inferência. Fornece **proveniência de resumo de nível de sessão** e progresso por arquivo, não texto de segmento traduzido ou revisão de saída traduzida.

### Progresso em tempo real nativo

Abra um WebSocket Phoenix persistente em `/native/socket/websocket?vsn=2.0.0` (`wss` em servidores HTTPS). Longpoll está desativado. Envie o token de acesso apenas através do cabeçalho de subprotocolo WebSocket, nunca através de parâmetros de consulta:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

O servidor negocia `phoenix`. Junte-se ao tópico `translation:<session UUID>` com `{"organization":"account-handle","project":"project-handle"}`. O valor de organização é o mesmo handle de conta usado pela API HTTP, incluindo contas pessoais. A resposta de junção e cada evento `snapshot` carregam a mesma projeção completa detalhada pela HTTP:

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

`seq` é a sequência de progresso durável, não **não** uma versão única de snapshot. Mudanças de status/publicação da sessão e contagens de chamadas de modelo em tempo real podem produzir um novo snapshot com a mesma sequência; substitua a projeção anterior mesmo quando `seq` permanecer inalterado. Os status por arquivo são `queued`, `running`, `done`, `failed` e `cancelled`. Caminhos, localidades e referências de arquivo podem ser `null` antes de serem conhecidos. Uma sessão intocada tem sequência zero, itens vazios e contagem zero. O resumo abrange **todos** os arquivos, mesmo quando itens são omitidos. Os identificadores de glossário/contagens do resumo são a agregação do redutor da web, não metadados do provedor.

No máximo 500 itens na ordem de índice planejada são incluídos, com um orçamento combinado de itens codificados de 512.000 bytes. Um item que não couber é omitido, e `omitted_items` conta cada linha excluída por qualquer limite. Saída traduzida crua, texto transmitido, raciocínio, cargas de provedor privadas e detalhes de falha crus nunca são incluídos. Contagens de chamadas de modelo públicas podem ser redefinidas após reconexão ou reconciliação; contagens finais duráveis e estados de arquivo são reconstruídos. Capturas nativas completas são limitadas a 1.000.000 de bytes JSON codificados. Se metadados de sessão não alterados ou o resumo completo sozinho exceder esse limite, a junção falha com `{"reason":"payload_too_large"}`, ou um canal existente recebe `error` com essa razão e fecha, ao invés de enviar um quadro superdimensionado ou truncar a procedência silenciosamente.

O servidor se inscreve no PubSub de sessão existente entre nós **antes** de ler o prefixo durável, compacta a cauda ao vivo com deduplicação de sequência e coalesce notificações de progresso/estado/publicação em capturas completas a aproximadamente 100 ms. Não é necessário polling HTTP por cliente ou estado local do runner. A cada cinco segundos, renova a autorização e reconstrói o estado durável para reparar notificações perdidas. Reconecte e rejo após colocar em primeiro plano ou após interrupção de transporte; a projeção de junção é suficiente sem reexibir deltas. Siga o ciclo normal de batida cardíaca do Phoenix enquanto estiver conectado, e abandone o tópico quando não estiver mais visualizando.

Concessão de token persistido atual, expiração/revogação, usuário, escopo de token `translation:read`, permissões de política, visibilidade do projeto e associação exata de conta/projeto/sessão são verificados na junção e antes de cada captura. Falta de escopo ou permissão de política retorna `{"reason":"forbidden"}`; recurso ausente retorna `{"reason":"not_found"}`; autenticação expirada/revogada retorna `{"reason":"sign_in_required"}`. Após uma junção bem-sucedida, a negação emite `access_revoked` com essa razão e fecha imediatamente o canal sem outra captura. Renovação também detecta revogação em canais ociosos. Em `sign_in_required`, renove/reautentique e crie uma nova conexão; para outras negações, pare de exibir o detalhe protegido. WebSockets são um mecanismo de atualização ao vivo em primeiro plano, não uma garantia de entrega enquanto o aplicativo móvel está suspenso.

## Análises

`GET /api/:handle/projects/:project/analytics?days=30` retorna métricas de resumo, até dez páginas mais acessadas, e a série temporal de tráfego. Um projeto vazio retorna:

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

`days` defaultya para `30` e deve ser um inteiro de `1` a `365`. A janela de relatórios UTC móvel termina no momento do pedido. Estas são as mesmas agregações de ClickHouse com escopo de projeto do painel, incluindo seus identificadores de visitantes com rotação diária. Falhas de armazenamento retornam `503` com `error: "analytics_unavailable"`, nunca métricas zero inventadas.

`traffic.granularity` é `"hour"` para janelas de até dois dias, `"day"` para janelas de até noventa dias e `"month"` caso contrário. `traffic.points` é cronológico. Cada ponto contém um timestamp de início de bucket UTC e contagens de inteiro não negativo:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Contagens incluem apenas eventos na janela de relatório solicitada, de forma que o primeiro e o último bucket podem ser parciais. Quando existem eventos, buckets silenciosos nesse intervalo são incluídos com contagens zero. Quando não existem eventos, `points` está vazio em vez de uma tendência plana sintética. `unique_visitors` conta identificadores distintos **em cada bucket**; somar esses valores não fornece a contagem de visitantes distintos do período. Use `summary.unique_visitors` para essa contagem total.

## Conversas do Toki

### Criar e listar

`POST /api/:handle/projects/:project/toki/conversations` aceita um UUID gerado pelo cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Retorna `201` com `{conversation, messages: []}`. Conversas vazias têm título `New conversation` e status `completed` (ocioso, não gerando). Reexibir o mesmo UUID para o mesmo ator, projeto e origem retorna o detalhe existente sem criar outra conversa. Reutilizar para outro ator, projeto ou origem retorna `409` com `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retorna `{conversations: [...], meta: {...}}`. Uma conversa contém `id`, `title`, `status`, `updated_at`, `error` nulo e `translation_session_id` nulo. Títulos são derivados da primeira mensagem de usuário, não de uma segunda chamada de modelo.

### Origem de tradução

Criação opcionalmente aceita um UUID de sessão de tradução do mesmo projeto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

A origem é imutável; omissão e `null` ambas indicam nenhuma origem. Uma tentativa de reinício deve fornecer a mesma origem, incluindo após enviar mensagens. Não é possível anexar uma origem posteriormente ou removê-la com uma tentativa de reinício. Uma origem malformada retorna `422`; uma fonte ausente ou de projeto estrangeiro retorna `404`. Criação vinculada à fonte adicionalmente exige `translation:read` escopo de token e permissão de política atual, juntamente com `toki:write` e permissão de leitura de projeto. Resumos de fonte fornecidos pelo cliente, metadados, funções e propriedade são ignorados. Apenas o UUID é persistido; o servidor resolve seu contexto autorizado no momento da resposta.

**Conversas vinculadas à fonte falham no fechamento**, ao invés de simplesmente redigir o UUID: sem escopo atual `translation:read` ou permissão de política, detalhe, reexibir criação de origem correspondente, envio de mensagem e reexibir mensagem retornam `403`. Uma origem incompatível ainda retorna `409` sem retornar histórico ou metadados de fonte. Listas omitem a conversa vinculada à fonte inteira, incluindo seu título e contribuição para contagens de paginação. Isso protege mensagens anteriores do assistente que podem mencionar a fonte. Escopos ausentes incluem o desafio normal `WWW-Authenticate`. Conversas não vinculadas mantêm seu comportamento de autorização apenas do Toki existente.

Fontes deletadas ou movidas também falham no fechamento: detalhe, envios e tentativas de reinício de criação vinculada à fonte retornam `404`, e listas omitem a conversa. O UUID imutável permanece armazenado após a exclusão da fonte para que uma tentativa de reinício não se torne não vinculada silenciosamente. A referência não tem uma chave estrangeira em cascata; cada uso verifica a existência atual da fonte e seu projeto/conta exato. Nenhuma referência de fonte concede acesso ou altera uma voz, glossário ou contexto compartilhado.

Criar ou abrir uma conversa vinculada à fonte não **envia** uma mensagem ou coloca na fila inferência. Navegação nativa deve buscar o detalhe da tradução primeiro; apenas uma ação de usuário explícita deve criar a conversa, e uma submissão de mensagem explícita separada inicia uma turno. Não há publicação de proposta, revisão de discussão compartilhada ou ferramentas de escrita de agente fornecidas.

### Enviar e consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` aceita um UUID de **mensagem** gerado separadamente pelo cliente:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

O pedido persiste a mensagem do usuário e uma tarefa do Oban em uma transação de banco de dados única. Não chama um modelo. Retorna `202` com status de conversa `queued` e as mensagens atuais. Consulte `GET /api/:handle/projects/:project/toki/conversations/:id` enquanto o status é `queued` ou `running`; pare em `completed` ou `failed`.

Respostas de detalhe têm esta forma:

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

Mensagens têm função `user` ou `assistant` e são cronológicas. Uma conversa contém no máximo 100 mensagens, de forma que o endpoint de detalhe retorna todo seu histórico limitado sem um pedido de página adicional.

Repetir um UUID de mensagem com conteúdo idêntico nunca cola outra inferência, inclusive após conclusão ou falha. Uma repetição resolvida retorna `200`; uma repetição pendente retorna `202`. Reutilizar um UUID com conteúdo diferente ou em outra conversa retorna `409`. Uma mensagem diferente enviada enquanto um turno está ativo retorna `409` com `error: "conversation_busy"`.

### Comportamento e limites do modelo

- Cada mensagem do usuário é texto não vazio, no máximo 8.000 caracteres e 32.000 bytes UTF-8. UUIDs inválidos, tipos ou conteúdo retornam `422`.
- Cada usuário pode ter no máximo 100 conversas por projeto e cinco conversas em fila/executando em todos os projetos. Mais de cinco turnos pendentes retorna `429`; limites de conversa/histórico retornam `422`.
- Novas mensagens são limitadas a 30 por hora por usuário por servidor, além dos limites de taxa normais da API. Retomas não consomem quota de inferência.
- A fila dedicada Oban executa duas tarefas simultaneamente por servidor. Cada turno realiza no máximo uma solicitação HTTP do provedor: o ReqLLM prepara a solicitação do provedor, então o trabalhador Oban executa-a.syncronously com tentativas de redirecionamento desativadas após o anexo do provedor. Nenhuma sessão Condukt, tarefa de inferência desacobrada, ferramentas, subagentes ou carregamento de instruções do sistema de arquivos está envolvido. O provedor recebe um teto de 2.048 tokens de saída; as respostas do assistente também são limitadas a 8.000 caracteres e 32.000 bytes.
- As esperas de conexão HTTP e do pool são limitadas a cinco segundos e as esperas de recepção do socket a sessenta segundos. O trabalhador Oban tem um prazo rígido de 90 segundos de relógio de parede, incluindo respostas gotejantes. A terminação do trabalhador também encerra sua execução local de inferência. Desconectar não garante o cancelamento de uma computação já aceita por um provedor remoto, portanto falhas ambíguas nunca são repetidas automaticamente.
- O modelo recebe metadados do projeto delimitados e no máximo três resumos recentes de tradução quando o token e os membros atuais permitir `translation:read`. Os últimos dez trechos de conversa são delimitados independentemente do armazenamento. Ele não possui capacidades de escrita ou acesso geral ao repositório, e nenhuma análise é fornecida ao modelo.
- Para uma conversa vinculada à fonte, o modelo recebe ainda a fonte persistente exata, mesmo que ela não seja recente: UUID, status, metadados de commit, idiomas, contagem e no máximo 1.000 caracteres de resumo. O contexto é marcado como `provenance: "session_summary"` e o prompt exige relatar esta limitação de nível de resumo. Nenhum texto de segmento, arquivos do repositório ou contexto de fonte fornecido pelo cliente é carregado.
- As credenciais são resolvidas através do modelo gerativo existente da conta e da configuração de inferência do servidor. Sessões interativas CLI/OAuth não são usadas para o Toki. Credenciais faltantes ou não suportadas geram status `failed` com `error: "provider_unavailable"`.
- Falhas do provedor produzem `inference_failed`; saída vazia ou excessiva produz `invalid_provider_response`. Erros brutos do provedor e segredos não são retornados. Nenhuma resposta sintética do assistente é inserida em caso de falha.
- Acesso à conta/projeto e existência da fonte, associação projeto/conta e autorização de tradução são verificados novamente antes e após a inferência. Acesso revogado ou escopos pendentes insuficientes falham o turno com `not_authorized`; fonte deletada ou movida falha com `source_unavailable`. Nenhuma resposta do assistente é persistida em nenhuma das falhas.
- Uma tarefa de recuperação roda a cada minuto e marca o trabalho em execução mais antigo que dois minutos, ou trabalho pendente mais antigo que quinze minutos, como `failed` com `inference_interrupted`. Isso resolve tarefas temporizadas, encerradas e órfãs sem reiniciar a inferência. Uma tarefa atrasada não pode reivindicar uma mensagem expirada ou sobrescrever um turno mais recente. Um usuário pode enviar deliberadamente um **novo** UUID de mensagem após uma falha.

## Erros

`401` significa que a autenticação falhou. `403` significa que o escopo ou a política de recursos negou acesso; escopos ausentes incluem um desafio `WWW-Authenticate`. Projetos desconhecidos e UUIDs de conversas estrangeiras/privadas retornam `404`. Validação usa `422`, paginação usa `400`, conflitos UUID/ocupados usam `409` e esgotamento de cota usa `429`.
