%{
  title: "API móvel e companheira",
  summary: "Aparência nativa, perfil, atividade de tradução, análises e conversas Toki privadas.",
  category: "Referência",
  subcategory: "APIs",
  order: 4
}
---

Todos os endpoints, exceto o catálogo de aparência nativa público, exigem um token de portador. A [especificação OpenAPI](/api/openapi.json) descreve os esquemas completos. Obtenha tokens através do [fluxo OAuth PKCE](/docs/reference/apis/authentication) existente. Nunca incorpore uma chave de provedor de inferência em um cliente.

## Autorização

| Endpoint | Escopo do token |
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

Escopos de token são um limite, não uma concessão. Cada endpoint de projeto também verifica a permissão de leitura do projeto do usuário. Um segundo escopo `project:read` **token** não é necessário, mas uma associação na organização com permissões explícitas deve permitir tanto leitura do projeto quanto a capacidade solicitada. Novas associações incluem essas capacidades móveis; associações explícitas existentes não são automaticamente alargadas.

Projetos pessoais seguem as regras de associação pessoal-organização existentes. A visibilidade da conta controla a leitura de projetos públicos; um visitor autenticado com o escopo necessário pode ler a atividade de tradução e análises de um projeto público. Escrever no Toki requer associação de conta, por isso apenas a visibilidade pública não gasta créditos de inferência da conta. Conversações de Toki permanecem privadas para o usuário criador no projeto, mesmo em contas públicas. Administradores de organização e plataforma não podem ler a conversa de outro usuário. Saber um UUID de conversa não concede acesso.

## Aparência nativa

`GET /api/native/themes` retorna metadados de aparência na escala da instância selecionada do servidor Glossia, sem autenticação ou dados de usuário/projeto. As respostas incluem `Cache-Control: public, max-age=300`. Isso não muda a autorização de qualquer endpoint de projeto.

A resposta possui quatro campos obrigatórios:

| Campo | Valor |
|---|---|
| `schema_version` | Inteiro `1` |
| `revision` | Revisão de conteúdo não em branco, no máximo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array contendo o tema padrão Glossia |

O tema padrão tem `id: "glossia"`, `name: "Glossia"`, uma descrição não em branco `description`, tipografia `typography: "standard"`, raio de botão `button_radius: 8`, raio de cartão `card_radius: 12`, e paletas `light` e `dark`. Raio são pixels lógicos numéricos. Cada paleta contém todos os nove campos a seguir, expressos como cores opacas `#RRGGBB`.

| Campo da paleta | Claro | Escuro |
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

O catálogo é compilado a partir dos tokens de cor e raio canônicos `:root` em `app/priv/static/assets/styles.css`. A paleta escura usa tokens semânticos exclusivos para nativo e não altera a renderização web. Recompilar após uma mudança de token atualiza o catálogo e sua revisão determinística. A revisão cobre o conteúdo do catálogo, não edições desvinculadas de folha de estilo. Não estão incluídas preferências por usuário nem configuração de tema em tempo de execução.

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

Listas de tradução e conversa recebem `page` (padrão `1`, intervalo `1–10000`) e `page_size` (padrão `20`, intervalo `1–50`). Valores inválidos retornam `400` em vez de clamping silencioso. Metadados usam a mesma forma que outras listas de API Glossia:

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

Listas refletem o estado atual, não um snapshot congelado. A ordenação da conversa é a mais recentemente atualizada primeiro, com UUID como desempate determinístico.

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

Statuses são `pending`, `running`, `completed`, `failed`, ou `cancelled`. Commit message, idioma original e resumo podem ser `null` enquanto o trabalho está pendente ou indisponível.

`GET /api/:handle/projects/:project/translations/:id` retorna `{session: {...}}` com exatamente os campos de sessão da lista mais o opcional `commit_sha`. Isso é uma pesquisa direta e exata de UUID dentro do projeto e conta endereçados, independente de paginação ou idade da sessão. IDs malformados, ausentes e de projeto estrangeiro retornam `404` com `error: "not_found"`; autenticação e autorização de projeto ainda rodam primeiro (`401`/`403`). Abrir este recurso nunca cria uma conversa, envia uma mensagem ou inicia inferência. Fornece **procedência de nível de resumo de sessão**, não texto de segmentos traduzidos ou exame de saída traduzida.

## Análises

`GET /api/:handle/projects/:project/analytics?days=30` retorna:

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

`days` padrão é `30` e deve ser um inteiro de `1` para `365`. A janela de relatórios UTC rodante termina no momento do pedido. Estes são os agregados de ClickHouse escopiados ao projeto do mesmo painel, incluindo seus identificadores de visitante rotacionados diariamente. A lista de top-pages contém no máximo dez entradas. Conjuntos de dados vazios retornam contagens zero, strings de valor topo vazias e uma lista de página vazia. Falhas de armazenamento retornam `503` com `error: "analytics_unavailable"`, nunca métricas zero inventadas.

## Conversas Toki

### Criar e listar

`POST /api/:handle/projects/:project/toki/conversations` aceita um UUID gerado pelo cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Retorna `201` com `{conversation, messages: []}`. Conversas vazias têm título `New conversation` e status `completed` (ocioso, não gerando). Reexecutar o mesmo UUID para o mesmo ator, projeto e origem retorna os detalhes existentes sem criar outra conversa. Reutilizá-lo para outro ator, projeto ou origem retorna `409` com `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retorna `{conversations: [...], meta: {...}}`. Uma conversa contém `id`, `title`, `status`, `updated_at`, opcional `error` e opcional `translation_session_id`. Títulos são derivados da primeira mensagem do usuário, não de uma segunda chamada do modelo.

### Origem de tradução

A criação opcionalmente aceita um UUID de sessão de tradução do mesmo projeto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

A origem é imutável; a omissão e `null` significam sem origem. Uma reintentação deve fornecer a mesma origem, incluindo depois de enviar mensagens. Não é possível anexar uma origem mais tarde ou removê-la com uma reintentação. Uma origem malformada retorna `422`; uma fonte ausente ou de projeto estrangeiro retorna `404`. A criação vinculada à fonte requer adicionalmente `translation:read` escopo de token e permissão de política atual, além de `toki:write` e permissão de leitura de projeto. Sumários, metadados, papéis e propriedade da fonte fornecidos pelo cliente são ignorados. Apenas o UUID é persistido; o servidor resolve seu contexto autorizado no momento da resposta.

**conversas vinculadas à origem falham fechadas**, em vez de meramente redigir o UUID: sem escopo atual `translation:read` ou permissão de política, detalhes, reexecução de criação vinculada à fonte, envio de mensagem e reexecução de mensagem retornam `403`. Uma origem incompatível ainda retorna `409` sem retornar histórico ou metadados da fonte. Listas omitem a conversa vinculada à fonte inteira, incluindo seu título e contribuição para os contagens de paginação. Isso protege mensagens anteriores do assistente que podem mencionar a fonte. Escopos ausentes incluem o desafio normal `WWW-Authenticate`. Conversas não vinculadas mantêm seu comportamento de autorização Toki existente.

Fontes exclusas ou movidas também falham fechadas: detalhes vinculados à fonte, envios e reintentagens de criação vinculada retornam `404` e as listas omitem a conversa. O UUID imutável permanece armazenado após a exclusão da fonte para que uma reintentação não possa silenciosamente se desvincular. A referência não possui chave estrangeira cascata; cada uso verifica a existência atual da fonte e seu projeto/conta exato. Nenhuma referência de fonte confere acesso ou muda uma voz, glossário ou contexto compartilhado.

Criar ou abrir uma conversa vinculada à fonte **não** envia uma mensagem ou enfileira inferência. A navegação nativa deve buscar o detalhe de tradução primeiro; apenas uma ação explícita do usuário deve criar a conversa, e uma submissão explícita de mensagem separada inicia uma rodada. Não é disponibilizado publicação de proposta, exame de discussão compartilhada ou ferramentas de escrita de agente.

### Enviar e consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` aceita um UUID separado gerado pelo cliente do **mensagem**:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

O pedido persiste a mensagem do usuário e um trabalho Oban em uma única transação de banco de dados. Não chama um modelo. Retorna `202` com status da conversa `queued` e as mensagens atuais. Consulte `GET /api/:handle/projects/:project/toki/conversations/:id` enquanto o status é `queued` ou `running`; pare em `completed` ou `failed`.

As respostas de detalhes têm este formato:

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

Mensagens têm papel `user` ou `assistant` e são cronológicas. Uma conversa contém no máximo 100 mensagens, então o endpoint de detalhes retorna todo seu histórico delimitado sem um adicional de solicitação de página.

Reexecutar um UUID de mensagem com conteúdo idêntico nunca enfileira outra inferência, incluindo depois de conclusão ou falha. Uma reexecução estabelecida retorna `200`; uma reexecução pendente retorna `202`. Reutilizar um UUID com conteúdo diferente ou em outra conversa retorna `409`. Uma mensagem diferente submetida enquanto uma rodada está ativa retorna `409` com `error: "conversation_busy"`.

### Comportamento e limites do modelo

- Cada mensagem do usuário é texto não em branco, no máximo 8.000 caracteres e 32.000 bytes UTF-8. UUIDs, tipos ou conteúdo inválidos retornam `422`.
- Cada usuário pode manter no máximo 100 conversas por projeto e cinco conversas na fila/executadas através de projetos. Mais de cinco rodadas pendentes retornam `429`; limites de conversa/histórico retornam `422`.
- Novas mensagens são limitadas a 30 por hora por usuário por servidor, além dos limites de taxa de API normais. Reexecuções não consomem cota de inferência.
- A fila dedicada do Oban executa dois trabalhos simultaneamente por servidor. Cada rodada faz no máximo uma requisição HTTP de provedor: o ReqLLM prepara a requisição do provedor, depois o trabalhador do Oban executa-a sincronamente com tentativas de reinício HTTP e redirecionos desabilitados depois do acesso do provedor. Nenhuma sessão Condukt, tarefa de inferência desvinculada, ferramentas, subagentes ou carregamento de instrução de sistema de arquivos está envolvido. O provedor recebe um teto de 2.048 tokens de saída; réplicas do assistente também são limitadas a 8.000 caracteres e 32.000 bytes.
- Aguardos de conexão e banco HTTP são limitados a cinco segundos e aguardos de recepção de socket a sessenta segundos. O trabalhador do Oban tem um limite duro de relógio de noventa segundos, incluindo respostas trincantes. A terminação do trabalhador também termina sua execução local de inferência. Desconectar não garante cancelamento de computação já aceita por um provedor remoto, assim falhas ambíguas nunca reiniciarão automaticamente.
- O modelo recebe metadados de projeto delimitados e até três resumos de tradução recentes quando tanto o token quanto a pertença atual permitem `translation:read`. Os últimos dez excertos de conversa são delimitados independentemente do armazenamento. Não possui capacidades de escrita ou acesso geral ao repositório, e nenhuma análise é fornecida ao modelo.
- Para uma conversa vinculada à fonte, o modelo recebe adicionalmente a fonte persistente exata, mesmo se não for recente: UUID, status, metadados de commit, idiomas, contagem e no máximo 1.000 caracteres de resumo. O contexto é marcado `provenance: "session_summary"`, e o prompt requer relatar esta limitação de nível de resumo. Nenhum texto de segmento, arquivos de repositório ou contexto de fonte fornecido pelo cliente é carregado.
- Credenciais resolvem através da configuração existente do modelo generativo da conta e da inferência do servidor. Sessões interativas CLI/OAuth não são usadas para Toki. Credenciais ausentes ou não suportadas produzem status `failed` com `error: "provider_unavailable"`.
- Falhas do provedor produzem `inference_failed`; saída vazia ou sobredimensionada produz `invalid_provider_response`. Erros brutos do provedor e segredos não retornam. Nenhuma réplica de assistente sintético é inserida na falha.
- Acesso de conta/projeto e existência da fonte, associação de projeto/conta e autorização de tradução são verificados novamente antes e depois da inferência. Acesso revogado ou escopos pendentes insuficientes falham a rodada com `not_authorized`; fonte excluída ou movida falha com `source_unavailable`. Nenhuma resposta do assistente é persistida em qualquer falha.
- Um trabalhador de recuperação corre a cada minuto e marca trabalhos em execução mais antigos que dois minutos, ou trabalhos pendentes mais antigos que quinze minutos, como `failed` com `inference_interrupted`. Isso resolve trabalhos com tempo limite, terminados e órfãos sem reeniciar inferência. Um trabalhador atrasado não pode reivindicar uma mensagem expirada ou sobrepor uma rodada mais recente. Um usuário pode enviar deliberadamente um **novo** UUID de mensagem após uma falha.

## Erros

`401` significa que a autenticação falhou. `403` significa que o escopo ou política de recursos negou acesso; escopos ausentes incluem um `WWW-Authenticate` desafio. Projetos desconhecidos e UUIDs de conversa estrangeiros ou privados retornam `404`. Validação usa `422`, paginação usa `400`, conflitos UUID/ocupados usam `409`, e exaurição de quota usa `429`.
