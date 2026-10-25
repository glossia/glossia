%{
  title: "API móvil y de acompañamiento",
  summary:
    "Apariencia nativa, perfil, actividad de traducción, análisis y conversaciones privadas de Toki.",
  category: "Referencia",
  subcategory: "APIs",
  order: 4
}
---

Todos los endpoints, excepto el catálogo de apariencia nativa público, requieren un token de portador. La [Especificación OpenAPI](/api/openapi.json) describe los esquemas completos. Obtenga los tokens a través del existente [flujo OAuth PKCE](/docs/reference/apis/authentication). Nunca incruste una clave de proveedor de inferencia en un cliente.

## Autorización

| Endpoint | Alcance del token |
|---|---|
| `GET /api/native/themes` | Ninguna (metadatos de apariencia pública) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Los alcances del token son un límite, no una concesión. Cada endpoint de proyecto también verifica el permiso de lectura de proyecto del usuario. No se requiere un segundo `project:read` **token**. Sin embargo, un miembro de la organización con permisos explícitos debe permitir tanto las lecturas de proyecto como la capacidad solicitada. Los nuevos miembros incluyen estas capacidades móviles; los miembros explícitos existentes no se amplían automáticamente.

Los proyectos personales siguen las reglas existentes de membresía de organización personal. La visibilidad de la cuenta controla las lecturas públicas de proyecto; un outsider autenticado con el alcance requerido puede leer la actividad de traducción y las analíticas de un proyecto público. Las escrituras en Toki requieren membresía de cuenta, por lo que la visibilidad pública por sí sola no gasta los créditos de inferencia de una cuenta. Las conversaciones en Toki permanecen privadas para su usuario creador dentro de su proyecto, incluso en cuentas públicas. Los administradores de organización y plataforma no pueden leer la conversación de otro usuario. Conocer un UUID de conversación no concede acceso.

## Apariencia nativa

`GET /api/native/themes` devuelve los metadatos de apariencia a nivel de instancia desde el servidor Glossia seleccionado, sin autenticación ni datos de usuario/proyecto. Las respuestas incluyen `Cache-Control: public, max-age=300`. Esto no altera la autorización de ningún endpoint de proyecto.

La respuesta tiene cuatro campos obligatorios:

| Campo | Valor |
|---|---|
| `schema_version` | Entero `1` |
| `revision` | Revisión de contenido no en blanco, a lo sumo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array que contiene el tema predeterminado de Glossia |

El tema predeterminado tiene `id: "glossia"`, `name: "Glossia"`, una `description` no en blanco, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, y `light` y `dark` paletas. Los radios son píxeles lógicos numéricos. Cada paleta contiene los nueve campos a continuación, expresados como colores `#RRGGBB` opacos:

| Campo de la paleta | Claro | Oscuro |
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

El catálogo se compila a partir de los tokens de color y radio `:root` canónico en `app/priv/static/assets/styles.css`. La paleta oscura utiliza tokens semánticos nativos únicamente y no cambia el renderizado web. Reconstruir después de un cambio de token actualiza el catálogo y su revisión determinista. La revisión abarca el contenido del catálogo, no ediciones de hoja de estilo no relacionadas. No se incluyen preferencias de usuario individuales ni configuración de tema en tiempo de ejecución.

## Perfil

`GET /api/me` devuelve solo el perfil del usuario autenticado:

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

`name` puede ser `null`. La cuenta asignada pertenece a la cuenta personal del usuario, no a la organización seleccionada. `server_version` es la versión de la aplicación en ejecución.

## Paginación

Las listas de traducción y conversación aceptan `page` (por defecto `1`, rango `1–10000`) y `page_size` (por defecto `20`, rango `1–50`). Los valores inválidos devuelven `400` en lugar de clamps. Los metadatos usan la misma forma que otras listas de API de Glossia:

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

Las listas reflejan el estado actual, no un instantáneo congelado. El orden de las conversaciones es el más recientemente actualizado primero, con UUID como desempate determinista.

## Actividad de traducción

`GET /api/:handle/projects/:project/translations?page=1` devuelve:

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

Los estados son `pending`, `running`, `completed`, `failed`, o `cancelled`. El mensaje de commit, el idioma de origen y el resumen pueden ser `null` mientras el trabajo está pendiente o cuando no está disponible. Los resultados son los más recientes primero y están restringidos al proyecto dirigido.

`GET /api/:handle/projects/:project/translations/:id` devuelve `{session: {...}, progress: {...}}`. El `session` tiene exactamente los campos de lista de sesión más el `commit_sha` nulo, sin cambios. `progress` se reconstruye desde eventos duraderos utilizando el mismo reductor de progreso Elixir como el panel web. Esto es una búsqueda directa y exacta de UUID dentro del proyecto y cuenta dirigidos, independiente de la paginación o la antigüedad de la sesión. Los IDs malformados, faltantes y de proyectos extranjeros devuelven `404` con `error: "not_found"`; la autenticación y autorización del proyecto se ejecutan primero (`401`/`403`). Abrir este recurso nunca crea una conversación, envía un mensaje o inicia inferencia. Proporciona **procedencia a nivel de resumen de sesión** y progreso por archivo, no texto de segmentos traducidos ni revisión del resultado traducido.

### Progreso nativo en tiempo real

Abra un WebSocket Phoenix persistente en `/native/socket/websocket?vsn=2.0.0` (`wss` en servidores HTTPS). El longpoll está desactivado. Envíe el token de acceso solo a través del encabezado de subprotocolo WebSocket, nunca a través de parámetros de consulta:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

El servidor negocia `phoenix`. Únase al tópico `translation:<session UUID>` con `{"organization":"account-handle","project":"project-handle"}`. El valor de organización es el mismo valor de cuenta usado por la API HTTP, incluyendo cuentas personales. La respuesta de joining y cada evento `snapshot` llevan la misma proyección completa que los detalles HTTP:

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

`seq` es la secuencia de progreso durable, **no** una versión de instantánea única. Los cambios de estado/publicación de sesión y los contados de llamadas en modelo en vivo pueden producir una nueva instantánea con la misma secuencia; reemplace la proyección anterior incluso cuando `seq` sea invariable. Los estados por archivo son `queued`, `running`, `done`, `failed`, y `cancelled`. Las rutas, localizaciones y referencias de archivo pueden ser `null` antes de que se sepan. Una sesión intacta tiene secuencia cero, ítems vacíos y conteos cero. El resumen cubre **todos** los archivos, incluso cuando los ítems se omiten. Los identificadores/conteos del glosario del resumen son la agregación del reductor web, no los metadatos del proveedor.

A lo sumo 500 ítems en orden de índice planificado se incluyen, con un presupuesto de ítem codificado combinado de 512.000 bytes. Un ítem que no puede caber se omite, y `omitted_items` cuenta cada fila excluida por cualquiera de los límites. La salida traducida en crudo, texto de transmisión, pensamiento, cargas de proveedor privadas y detalles de falla crudos nunca se incluyen. Contados de llamadas de modelo público en vivo pueden reiniciarse después de reconexión o reconciliación; contados finales duraderos y estados de archivo se reconstruyen. Las instantáneas nativas completas están limitadas a 1.000.000 de bytes codificados JSON. Si los metadatos de sesión invariables o el resumen completo por sí solo exceden ese límite, la unión falla con `{"reason":"payload_too_large"}`, o un canal existente recibe `error` con ese motivo y cierra, en lugar de enviar un marco de tamaño excesivo o truncar silenciosamente la procedencia.

El servidor se suscribe al PubSub de sesión cruzada existente **antes** de leer el prefijo durable, dobla la cola en vivo con eliminación de duplicados de secuencia y funde las notificaciones de progreso/estado/publicación en instantáneas completas de aproximadamente 100 ms. No se necesita HTTP polling por cliente ni estado del ejecutor local. Cada cinco segundos renueva la autorización y reconstruye el estado durable para reparar notificaciones perdidas. Reconéctese y únase de nuevo después de poner en primer plano o una interrupción de transporte; la proyección de unión es suficiente sin reproducir deltas. Siga el ciclo de vida normal del latido Phoenix mientras esté conectado y deje el tópico cuando deje de verlo.

La concesión de token persistente actual, caducidad/revocación, usuario, `translation:read` alcance del token, permisos de política, visibilidad del proyecto y asociación exacta de cuenta/proyecto/sesión se comprueban al unirse y antes de cada instantánea. Alcance faltante o permiso de política devuelve `{"reason":"forbidden"}`; un recurso faltante devuelve `{"reason":"not_found"}`; autenticación caducada/revocada devuelve `{"reason":"sign_in_required"}`. Después de una unión exitosa, el rechazo emite `access_revoked` con ese motivo y cierra el canal inmediatamente sin otra instantánea. La renovación también detecta la revocación en canales inactivos. En `sign_in_required`, actualizarse/reautenticarse y cree una nueva conexión; en otros rechazos, deje de mostrar el detalle protegido. WebSockets son un mecanismo de actualización en vivo de primer plano, no una garantía de entrega mientras la aplicación móvil esté suspendida.

## Analítica

`GET /api/:handle/projects/:project/analytics?days=30` devuelve métricas resumen, hasta diez páginas principales y la serie temporal de tráfico. Un proyecto vacío devuelve:

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

`days` tiene como predeterminado `30` y debe ser un entero de `1` a `365`. La ventana de informe UTC corrientemente termina al momento de solicitud. Son las mismas agregaciones de ClickHouse con alcance de proyecto que el tablero, incluidos sus identificadores de visitantes rotados diariamente. Las fallas de almacenamiento devuelven `503` con `error: "analytics_unavailable"`, nunca métricas nulas inventadas.

`traffic.granularity` es `"hour"` para ventanas de hasta dos días, `"day"` para ventanas de hasta noventa días y `"month"` en lo contrario. `traffic.points` es cronológico. Cada punto contiene un inicio de bucket UTC y conteos enteros no negativos:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Los conteos incluyen solo eventos en la ventana de informe solicitada, por lo que los primeros y últimos buckets pueden ser parciales. Cuando existen eventos, los buckets silenciosos en esa ventana se incluyen con conteos cero. Cuando no existen eventos, `points` es vacío en lugar de una tendencia plana sintética. `unique_visitors` cuenta identificadores distintos **en cada bucket**; sumar estos valores no da el conteo de visitantes distintos del periodo. Use `summary.unique_visitors` para ese total. Los clientes deben trazar los buckets devueltos sin cambios en lugar de reconstruir una tendencia a partir de métricas resumen.

## Conversaciones Toki

### Crear y listar

`POST /api/:handle/projects/:project/toki/conversations` acepta un UUID generado por cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Devuelve `201` con `{conversation, messages: []}`. Las conversaciones vacías tienen título `New conversation` y estado `completed` (inactivo, no generando). Reenviar el mismo UUID para el mismo actor, proyecto y origen devuelve el detalle existente sin crear otra conversación. Reutilizarlo para otro actor, proyecto o origen devuelve `409` con `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` devuelve `{conversations: [...], meta: {...}}`. Una conversación contiene `id`, `title`, `status`, `updated_at`, nulo `error` y nulo `translation_session_id`. Los títulos se derivan del primer mensaje de usuario, no de una segunda llamada al modelo.

### Origen de traducción

La creación acepta opcionalmente un UUID de sesión de traducción del mismo proyecto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

El origen es inmutable; la omisión y `null` significan ambos sin origen. El reenvío debe proveer el mismo origen, incluso después de enviar mensajes. No puede adjuntar un origen más tarde ni quitar uno con un reenvío. Un origen malformado devuelve `422`; una fuente faltante o de proyecto ajeno devuelve `404`. La creación enlazada a la fuente requiere además `translation:read` alcance de token y permiso de política actual, junto con `toki:write` y permiso de proyecto-lectura. Los resúmenes de fuente, metadatos, roles y propiedad suministrados por el cliente se ignoran. Solo el UUID se almacena persistentemente; el servidor resuelve su contexto autorizado al momento de la respuesta.

**Las conversaciones enlazadas a la fuente fallan en modo cerrado**, en lugar de simplemente enmascarar el UUID: sin alcance actual `translation:read` o permiso de política, detalle, reenvío de creación de origen coincidente, envío de mensaje y reenvío de mensaje devuelven `403`. Un origen no coincidente devuelve `409` sin devolver historia o metadatos de fuente. Las listas omiten toda la conversación enlazada a la fuente, incluido su título y contribución a los conteos de paginación. Esto protege los mensajes anteriores del asistente que podrían mencionar la fuente. Los alcances faltantes incluyen el desafío normal `WWW-Authenticate`. Las conversaciones no enlazadas mantienen su comportamiento de autorización Toki existente.

Fuentes eliminadas o movidas también fallan en modo cerrado: el detalle enlazado a la fuente, envíos y reenvíos de creación coincidente devuelven `404`, y las listas omiten la conversación. La UUID inmutable permanece almacenada después de la eliminación de la fuente para que un reenvío no pueda silenciosamente volverse no enlazado. La referencia no tiene clave foránea cascada; cada uso verifica existencia actual de fuente y su proyecto/admin exacto. Ninguna referencia de fuente otorga acceso o cambia una voz, glosario o contexto compartido.

Crear o abrir una conversación enlazada a la fuente **no** envía un mensaje ni encola inferencia. La navegación nativa debe buscar primero el detalle de traducción; solo una acción explícita del usuario debe crear la conversación, y un envío de mensaje explícito separado inicia un turno. No se proporciona publicación de propuestas, revisión de discusión compartida o herramientas de escritura de agente.

### Enviar y consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` acepta un UUID de mensaje **separado** generado por cliente:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La solicitud mantiene el mensaje de usuario y un trabajo de Oban en una transacción de base de datos. No llama a un modelo. Devuelve `202` con el estado de conversación `queued` y los mensajes actuales. Consultar `GET /api/:handle/projects/:project/toki/conversations/:id` mientras el estado es `queued` o `running`; detenerse en `completed` o `failed`.

Las respuestas de detalle tienen esta forma:

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

Los mensajes tienen el rol `user` o `assistant` y son cronológicos. Una conversación contiene a lo sumo 100 mensajes, por lo que el endpoint de detalle devuelve su historia completa delimitada sin solicitar una página adicional.

Reenviar una UUID de mensaje con contenido idéntico nunca encola otra inferencia, incluso después de la finalización o el fallo. Un reenvío consolidado devuelve `200`; un reenvío pendiente devuelve `202`. Reutilizar una UUID con contenido distinto o en otra conversación devuelve `409`. Enviar un mensaje distinto mientras un turno está activo devuelve `409` con `error: "conversation_busy"`.

### Comportamiento del modelo y límites

- Cada mensaje de usuario es texto no vacío, a lo sumo 8,000 caracteres y 32,000 bytes UTF-8. UUIDs, tipos o contenido inválidos devuelven `422`
- Cada usuario puede tener a lo sumo 100 conversaciones por proyecto y cinco conversaciones en cola/en ejecución a través de proyectos. Más de cinco turnos pendientes devuelve `429`; los límites de conversación/historial devuelven `422`
- Los mensajes nuevos se limitan a 30 por hora por usuario por servidor, además de los límites de tasa de API normales. Los reenvíos no consumen cuota de inferencia.
- La cola dedicada de Oban ejecuta dos trabajos concurrentemente por servidor. Cada turno realiza a lo sumo una solicitud HTTP de proveedor: ReqLLM prepara la solicitud del proveedor, luego el worker de Oban la ejecuta sincrónicamente con reintentos HTTP y redirecciones deshabilitadas después del adjuntado de proveedor. No hay sesión de Condukt, tarea de inferencia desacoplada, herramientas, subagentes o carga de instrucciones del sistema de archivos involucrado. El proveedor recibe un techo de 2.048 tokens de salida; las respuestas del asistente también se limitan a 8.000 caracteres y 32.000 bytes.
- Las esperas de conexión HTTP y de pool se limitan a cinco segundos y las esperas de recepción de socket a sesenta segundos. El worker de Oban tiene un límite estricto de tiempo de reloj de noventa segundos, incluyendo respuestas de goteo. La terminación del worker también termina su ejecución local de inferencia. desconectarse no puede garantizar la cancelación del cómputo ya aceptado por un proveedor remoto, por lo que los fallos ambiguos nunca se reintentan automáticamente.
- El modelo recibe metadatos de proyecto delimitados y a lo sumo tres resúmenes de traducción recientes cuando tanto el token como el membresía actual permiten `translation:read`. Los últimos diez fragmentos de conversación están delimitados independientemente del almacenamiento. No tiene capacidades de escritura ni acceso general al repositorio y no se proveen analíticas al modelo.
- Para una conversación enlazada a una fuente, el modelo recibe adicionalmente la fuente persistente exacta, incluso si no es reciente: UUID, estado, metadatos de commit, lenguajes, conteo y a lo sumo 1.000 caracteres de resumen. El contexto está etiquetado `provenance: "session_summary"` y el prompt requiere reportar esta limitación de nivel de resumen. No se carga texto de segmento, archivos del repositorio o contexto de fuente proporcionado por cliente.
- Las credenciales se resuelven a través del modelo generativo existente de la cuenta y la configuración de inferencia del servidor. Las sesiones interactivas CLI/OAuth no se usan para Toki. Las credenciales faltantes o no soportadas producen estado `failed` con `error: "provider_unavailable"`.
- Los fallos del proveedor producen `inference_failed`; la salida vacía o de tamaño excesivo produce `invalid_provider_response`. Los errores crudos del proveedor y los secretos no se devuelven. No se inserta ninguna respuesta sintética de asistente al fracaso.
- El acceso a la cuenta/proyecto y la existencia de fuente, la asociación de proyecto/cuenta y la autorización de traducción se vuelven a verificar antes y después de la inferencia. El acceso revocado o las colas de ámbito insuficientes fallan el turno con `not_authorized`; una fuente eliminada o movida falla con `source_unavailable`. No se persista ninguna respuesta de asistente en uno u otro fallo.
- Un trabajo de recuperación corre cada minuto y marca como `failed` trabajos en ejecución con más de dos minutos o trabajos cola con más de quince minutos con `inference_interrupted`. Esto resuelve trabajos con tiempo de espera, terminados y huérfanos sin reintentar inferencia. Un trabajo retrasado no puede reclamar un mensaje expirado ni sobreescribir un turno más nuevo. Un usuario puede enviar deliberadamente una UUID de mensaje **actual** tras un fallo.

## Errores

`401` significa que la autenticación falló. `403` significa que el ámbito o la política de recurso denegó el acceso; los ámbitos faltantes incluyen un desafío `WWW-Authenticate`. Proyectos desconocidos y UUIDs de conversación extranjeras/privadas devuelven `404`. La validación usa `422`, la paginación usa `400`, los conflictos UUID/ocupados usan `409` y el agotamiento de cuota usa `429`.
