%{
  title: "API móvil y de acompañamiento",
  summary:
    "Apariencia nativa, perfil, actividad de traducción, analíticas y conversaciones privadas de Toki.",
  category: "Referencia",
  subcategory: "APIs",
  order: 4
}
---

Todos los endpoints excepto el catálogo de apariencia nativa público requieren un token bearer. La [Especificación OpenAPI](/api/openapi.json) describe los esquemas completos. Obtenga tokens a través del flujo existente [OAuth PKCE](/docs/reference/apis/authentication). Nunca incruste una clave de proveedor de inferencia en un cliente.

## Autorización

| Endpoint | Alcance de token |
|---|---|
| `GET /api/native/themes` | Ninguno (metadatos de apariencia pública) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Los alcances de token son un límite, no una concesión. Cada punto final de proyecto también revisa el permiso de lectura de proyecto del usuario. Un segundo `project:read` **token** alcance no es requerido, pero una membresía de organización con permisos explícitos debe permitir tanto las lecturas de proyecto como la capacidad solicitada. Las nuevas membresías incluyen estas capacidades móviles; las membresías explícitas existentes no se ensanchan automáticamente.

Los proyectos personales siguen las reglas existentes de membresía de organización personal. La visibilidad de la cuenta controla las lecturas de proyecto públicas; un usuario autenticado externo con el alcance requerido puede leer la actividad y análisis de traducción de un proyecto público. La escritura de Toki requiere membresía de cuenta, por lo que la visibilidad pública por sí sola no consume los créditos de inferencia de una cuenta. Las conversaciones Toki permanecen privadas para su usuario creador dentro de su proyecto, incluso en cuentas públicas. Los administradores de organización y plataforma no pueden leer la conversación de otro usuario. Conocer un UUID de conversación no otorga acceso.

## Apariencia nativa

`GET /api/native/themes` devuelve metadatos de apariencia a nivel de instancia desde el servidor Glossia seleccionado, sin autenticación ni datos de usuario o proyecto. Las respuestas incluyen `Cache-Control: public, max-age=300`. Esto no cambia la autorización para ningún punto final de proyecto.

La respuesta tiene cuatro campos requeridos:

| Campo | Valor |
|---|---|
| `schema_version` | Entero `1` |
| `revision` | Revisión de contenido sin espacios en blanco, como máximo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array containing the default Glossia theme |

El tema predeterminado tiene `id: "glossia"`, `name: "Glossia"`, una `description` no en blanco, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, y `light` y `dark` paletas. Los radios son píxeles lógicos numéricos. Cada paleta contiene los nueve campos a continuación, expresados como colores `#RRGGBB` opacos:

| Campo de paleta | Claro | Oscuro |
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

El catálogo se compila desde los tokens de color y radio `:root` canónicos en `app/priv/static/assets/styles.css`. La paleta oscura usa tokens semánticos solo nativos y no cambia el renderizado web. La reconstrucción tras un cambio de token actualiza el catálogo y su revisión determinística. La revisión cubre el contenido del catálogo, no ediciones de hoja de estilo no relacionadas. No se incluyen preferencias por usuario ni configuración de tema en tiempo de ejecución.

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

`name` puede ser `null`. El handle pertenece a la cuenta personal del usuario, no a la organización seleccionada. `server_version` es la versión de la aplicación en ejecución.

## Paginación

Las listas de traducción y conversación aceptan `page` (por defecto `1`, rango `1–10000`) y `page_size` (por defecto `20`, rango `1–50`). Los valores inválidos retornan `400` en lugar de ajustar silenciosamente. Los metadatos usan la misma forma que otras listas de API de Glossia:

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

Las listas reflejan el estado actual, no un snapshot congelado. El orden de las conversaciones es el más recientemente actualizado primero, con UUID como desempate determinístico.

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

Los estados son `pending`, `running`, `completed`, `failed` o `cancelled`. El mensaje de compromiso, idioma de origen y resumen pueden ser `null` mientras el trabajo está pendiente o no está disponible. Los resultados son primero los más nuevos y están restringidos al proyecto abordado.

`GET /api/:handle/projects/:project/translations/:id` devuelve `{session: {...}}` con exactamente los campos de sesión de lista más `commit_sha` nulo. Esto es una búsqueda directa y exacta de UUID dentro del proyecto y cuenta abordados, independiente de paginación o edad de sesión. Los IDs malformados, faltantes y extraños al proyecto devuelven `404` con `error: "not_found"`; autenticación y autorización de proyecto aún primero se ejecutan (`401`/`403`). Abrir este recurso nunca crea una conversación, envía un mensaje o inicia inferencia. Proporciona **procedencia a nivel de resumen de sesión**, no texto de segmento traducido ni revisión de salida traducida.

## Análisis

`GET /api/:handle/projects/:project/analytics?days=30` devuelve:

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

`days` por defecto es `30` y debe ser un entero de `1` a `365`. La ventana de reporte UTC en tiempo corrido termina al momento de la solicitud. Estas son las mismas agregaciones de ClickHouse con ámbito de proyecto que el panel, incluyendo sus identificadores de visitante rotados diariamente. La lista de top-pages contiene como máximo diez entradas. Los conjuntos de datos vacíos devuelven conteos cero, cadenas de valor vacías y una lista de página vacía. Los fallos de almacenamiento devuelven `503` con `error: "analytics_unavailable"`, nunca métricas cero inventadas.

## Conversaciones Toki

### Crear y listar

`POST /api/:handle/projects/:project/toki/conversations` acepta un UUID generado por el cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Devuelve `201` con `{conversation, messages: []}`. Las conversaciones vacías tienen título `New conversation` y estado `completed` (inactivo, no generando). Reproduciendo el mismo UUID para el mismo actor, proyecto y origen devuelve el detalle existente sin crear otra conversación. Reutilizándolo para otro actor, proyecto u origen devuelve `409` con `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` devuelve `{conversations: [...], meta: {...}}`. Una conversación contiene `id`, `title`, `status`, `updated_at`, `error` nulo, y `translation_session_id` nulo. Los títulos se derivan del primer mensaje del usuario, no de una segunda llamada de modelo.

### Origen de traducción

La creación acepta opcionalmente un UUID de sesión de traducción del mismo proyecto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

El origen es inmutable; la omisión y `null` significan no tener origen. Una reintentación debe proveer el mismo origen, incluso después de enviar mensajes. No se puede adjuntar un origen posteriormente ni eliminarlo mediante una reintentación. Un origen malformado devuelve `422`; una fuente faltante o de proyecto externo devuelve `404`. La creación enlazada a la fuente requiere adicionalmente el alcance del token `translation:read` y permiso de política actual, junto con `toki:write` y permiso de lectura de proyecto. Las sumarias de fuente, metadatos, roles y propiedad suministrados por el cliente se ignoran. Solo el UUID se persiste; el servidor resuelve su contexto autorizado al momento de la respuesta.

**Conversaciones enlazadas a la fuente fallan de forma cerrada**, en lugar de simplemente redactar el UUID: sin alcance `translation:read` actual o permiso de política, detalle, creación de reproducción de origen coincidente, envío de mensaje y reproducción de mensaje devuelven `403`. Un origen incorrecto aún devuelve `409` sin devolver historial o metadatos de fuente. Las listas omiten la conversación enlazada a la fuente completa, incluido su título y contribución a los conteos de paginación. Esto protege los mensajes iniciales del asistente que podrían mencionar la fuente. Los alcances faltantes incluyen el desafío `WWW-Authenticate` normal. Las conversaciones desvinculadas mantienen su comportamiento de autorización exclusivo de Toki.

Las fuentes eliminadas o movidas también fallan de forma cerrada: el detalle enlazado a la fuente, envíos y reintentaciones de creación coincidentes devuelven `404` y las listas omiten la conversación. El UUID inmutable permanece almacenado después de la eliminación de la fuente para que una reintentación no se desvincule silenciosamente. La referencia no tiene clave foránea en cascada; cada uso verifica la existencia actual de la fuente y su proyecto/cuenta exacta. Ninguna referencia de fuente concede acceso ni cambia la voz, glosario o contexto compartido.

Al crear o abrir una conversación enlazada a la fuente **no** envía un mensaje ni encola inferencia. La navegación nativa debe obtener primero el detalle de la traducción; solo una acción de usuario explícita debería crear la conversación, y un envío de mensaje explícito separado inicia un turno. No se proporciona publicación de propuesta, revisión compartida de discusión o herramientas de escritura de agente.

### Enviar y consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` acepta un UUID de **mensaje** separado generado por el cliente:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La solicitud conserva el mensaje de usuario y una tarea Oban en una sola transacción de base de datos. No llama a un modelo. Devuelve `202` con estado de conversación `queued` y los mensajes actuales. Consultar `GET /api/:handle/projects/:project/toki/conversations/:id` mientras el estado sea `queued` o `running`; detenerse en `completed` o `failed`.

Las respuestas al detalle tienen esta forma:

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

Los mensajes tienen rol `user` o `assistant` y son cronológicos. Una conversación contiene como máximo 100 mensajes, por lo que el punto de acceso al detalle devuelve su historial acotado completo sin una solicitud de página adicional.

La repetición de un UUID de mensaje con contenido idéntico nunca encola otra inferencia, incluso tras la finalización o el fallo. Una repetición establecida devuelve `200`; una repetición pendiente devuelve `202`. Reutilizar un UUID con contenido diferente o en otra conversación devuelve `409`. Un mensaje diferente enviado mientras un turno está activo devuelve `409` con `error: "conversation_busy"`.

### Comportamiento y límites del modelo

- Cada mensaje de usuario es texto no en blanco, como máximo 8,000 caracteres y 32,000 bytes UTF-8. UUIDs, tipos o contenido inválidos devuelven `422`.
- Cada usuario puede guardar como máximo 100 conversaciones por proyecto y cinco conversaciones colas/ejecución entre proyectos. Más de cinco giros pendientes devuelve `429`; los límites de conversación/historial devuelven `422`.
- Los nuevos mensajes se limitan a 30 por hora por usuario por servidor, además de los límites de velocidad de API normales. Las reproducciones no consumen cuota de inferencia.
- La cola dedicada Oban ejecuta dos trabajos simultáneamente por servidor. Cada turno realiza como máximo una petición HTTP del proveedor: ReqLLM prepara la petición del proveedor, luego el trabajador Oban la ejecuta de manera sincronizada con reintentos HTTP y redirecciones deshabilitadas tras la adjunción del proveedor. No se involucra sesión de Condukt, tarea de inferencia desvinculada, herramientas, subagentes o carga de instrucciones del sistema de archivo. El proveedor recibe un límite de 2,048 tokens de salida; las respuestas del asistente también se limitan a 8,000 caracteres y 32,000 bytes.
- Las conexiones HTTP y las esperas de memoria están limitadas a cinco segundos y las esperas de recepción de puerto a sesenta segundos. El trabajador Oban tiene un límite de tiempo fijo de ninety-segundos con hora real de reloj, incluyendo las respuestas que gotean. La terminación del trabajador también termina su ejecución local de inferencia. Desconectar no puede garantizar la cancelación de un cálculo ya aceptado por un proveedor remoto, por lo que no se reintentan automáticamente los fallos ambiguos.
- El modelo recibe metadatos de proyecto acotados y como máximo tres resúmenes de traducción recientes cuando tanto el token y el membresía actual permiten `translation:read`. Los últimos diez extractos de conversación están acotados independientemente del almacenamiento. No tiene capacidades de escritura ni acceso general al repositorio, y no se suministran análisis al modelo.
- Para una conversación enlazada a la fuente, el modelo recibe adicionalmente la fuente persistida exacta, incluso si no es reciente: UUID, estado, metadatos del commit, idiomas, conteo y como máximo 1,000 caracteres de resumen. El contexto está etiquetado `provenance: "session_summary"`, y el prompt requiere reportar esta limitación a nivel de resumen. No se carga texto de segmento, archivos del repositorio o contexto de fuente suministrado por el cliente.
- Las credenciales se resuelven mediante el modelo generativo existente de la cuenta y la configuración de inferencia del servidor. Las sesiones interactivas CLI/OAuth no se utilizan para Toki. Las credenciales faltantes o sin soporte generan estado `failed` con `error: "provider_unavailable"`.
- Los fallos del proveedor producen `inference_failed`; el vacío o el tamaño excesivo de la salida produce `invalid_provider_response`. Los errores crudos del proveedor y secretos no se devuelven. No se inserta una respuesta de asistente sintética ante el fallo.
- El acceso de cuenta/proyecto y la existencia de la fuente, asociación de proyecto/cuenta y autorización de traducción se verifican nuevamente antes y después de la inferencia. El acceso revocado o los alcances colas insuficientes fallan el turno con `not_authorized`; una fuente eliminada o movida falla con `source_unavailable`. No se persiste ninguna respuesta de asistente en ningún fallo.
- Una tarea de recuperación se ejecuta cada minuto y marca como `failed` con `inference_interrupted` el trabajo en ejecución más antiguo que dos minutos, o el trabajo en cola más antiguo que quince minutos. Esto finaliza las tareas con tiempo agotado, terminadas y huérfanas sin reintentar inferencia. Una tarea retrasada no puede reclamar un mensaje caducado ni sobrescribir un turno más reciente. Un usuario puede deliberadamente enviar un **nuevo** UUID de mensaje después de un fallo.

## Errores

`401` significa que la autenticación falló. `403` significa que el alcance o la política de recursos negó el acceso; los alcances faltantes incluyen un `WWW-Authenticate` desafío. Los proyectos desconocidos y los UUID de conversación extranjeros o privados devuelven `404`. La validación usa `422`, la paginación usa `400`, los conflictos de UUID/ocupados usan `409` y el agotamiento de cuota usa `429`.
