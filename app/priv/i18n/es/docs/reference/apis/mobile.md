%{
  title: "API móvil y de acompañamiento",
  summary:
    "Apariencia nativa, perfil, actividad de traducción, analíticas y conversaciones privadas de Toki.",
  category: "Referencia",
  subcategory: "APIs",
  order: 4
}
---

Todos los endpoints excepto el catálogo de apariencia nativa público requieren un token Bearer. La [Especificación OpenAPI](/api/openapi.json) describe los esquemas completos. Obtenga los tokens a través del existente [flujo OAuth PKCE](/docs/reference/apis/authentication). Nunca incruste una clave de proveedor de inferencia en un cliente.

## Autorización

| Endpoint | Alcance de token |
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

El alcance de los token es un límite, no una concesión. Cada endpoint de proyecto también verifica el permiso de lectura de proyecto del usuario. Un segundo `project:read` **token** scope no es necesario, pero una membresía de organización con permisos explícitos debe permitir tanto las lecturas de proyecto como la capacidad solicitada. Las nuevas membresías incluyen estas capacidades móviles; las membresías explícitas existentes no se amplían automáticamente.

Los proyectos personales siguen las reglas existentes de membresía personal-org. La visibilidad de cuenta controla las lecturas públicas de proyecto; un extraño autenticado con el alcance requerido puede leer la actividad de traducción y los análisis de un proyecto público. Las escrituras de Toki requieren membresía de cuenta, por lo que la visibilidad pública por sí sola no gasta los créditos de inferencia de una cuenta. Las conversaciones de Toki permanecen privadas para el usuario que las creó dentro de su proyecto, incluso en cuentas públicas. Los administradores de organización y plataforma no pueden leer la conversación de otro usuario. Conocer un UUID de conversación no otorga acceso.

## Apariencia nativa

`GET /api/native/themes` devuelve metadatos de apariencia de todas las instancias del servidor Glossia seleccionado, sin autenticación ni datos de usuario/proyecto. Las respuestas incluyen `Cache-Control: public, max-age=300`. Esto no cambia la autorización para ningún endpoint de proyecto.

La respuesta tiene cuatro campos obligatorios:

| Campo | Valor |
|---|---|
| `schema_version` | Entero `1` |
| `revision` | Revisión de contenido no en blanco, como máximo 128 caracteres |
| `default_theme_id` | `"glossia"` |
| `themes` | Array que contiene el tema predeterminado de Glossia |

El tema por defecto tiene `id: "glossia"`, `name: "Glossia"`, una `description` no vacía, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` y `light` y `dark` paletas. Los radios son píxeles lógicos numéricos. Cada paleta contiene los nueve campos a continuación, expresados como colores `#RRGGBB` opacos:

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

El catálogo se compila desde los tokens de color y radio canónicos `:root` en `app/priv/static/assets/styles.css`. La paleta oscura usa tokens semánticos nativos y no cambia el renderizado web. La reconstrucción después de un cambio de token actualiza el catálogo y su revisión determinista. La revisión cubre el contenido del catálogo, no las ediciones de hoja de estilo no relacionadas. No se incluyen preferencias por usuario ni configuración de tema en tiempo de ejecución.

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

`name` puede ser `null`. El identificador pertenece a la cuenta personal del usuario, no a la organización seleccionada. `server_version` es la versión de la aplicación en ejecución.

## Paginación

Las listas de traducción y conversación aceptan `page` (por defecto `1`, rango `1–10000`) y `page_size` (por defecto `20`, rango `1–50`). Los valores inválidos devuelven `400` en lugar de ajustar silenciosamente. Los metadatos usan la misma forma que otras listas de los API Glossia:

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

Las listas reflejan el estado actual, no una instantánea congelada. El orden de las conversaciones es la más actualizada recientemente primero, con UUID como desempate determinista.

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

Los estados son `pending`, `running`, `completed`, `failed` o `cancelled`. El mensaje de commit, el idioma origen y el resumen pueden ser `null` mientras el trabajo está pendiente o cuando no estén disponibles. Los resultados son primero los más recientes y están restringidos al proyecto indicado.

`GET /api/:handle/projects/:project/translations/:id` devuelve `{session: {...}, progress: {...}}`. El `session` tiene exactamente los campos de lista de sesión más `commit_sha` (opcionalmente nulo), sin cambios. `progress` se reconstruye desde eventos duraderos usando el mismo reductor de progreso Elixir que el panel web. Esta es una búsqueda directa y exacta de UUID dentro del proyecto y cuenta indicados, independientemente de la paginación o la edad de la sesión. Los IDs malformados, faltantes y de proyectos extranjeros devuelven `404` con `error: "not_found"`; la autenticación y autorización de proyecto se ejecutan primero (`401`/`403`). Abrir este recurso nunca crea una conversación, envía un mensaje o inicia inferencia. Proporciona **procedencia a nivel de resumen de sesión** y progreso por archivo, no texto de segmento traducido o revisión de salida traducida.

### Progreso nativo en tiempo real

Abra un WebSocket persistente Phoenix en `/native/socket/websocket?vsn=2.0.0` (`wss` en servidores HTTPS). El longpoll está desactivado. Envíe el token de acceso solo a través del encabezado de subprotocolo WebSocket, nunca a través de parámetros de consulta:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

El servidor negocia `phoenix`. Únase al tema `translation:<session UUID>` con `{"organization":"account-handle","project":"project-handle"}`. El valor de organización es el same manejador de cuenta usado por el API HTTP, incluidas las cuentas personales. La respuesta de unión y cada evento `snapshot` lleva la misma proyección completa que el detalle HTTP:

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

`seq` es la secuencia de progreso durable, **no** una versión única de instantánea. Los cambios de estado/publicación de la sesión y los conteos de llamadas de modelo en directo pueden producir una nueva instantánea con la misma secuencia; reemplace la proyección anterior incluso cuando `seq` se mantenga inalterada. Los estados por archivo son `queued`, `running`, `done`, `failed` y `cancelled`. Las rutas, localizaciones y referencias de archivo pueden ser `null` antes de ser conocidas. Una sesión inalterada tiene secuencia cero, elementos vacíos y conteos cero. El resumen abarca **todos** los archivos, incluso cuando los ítems son omitidos. Los identificadores/contadores de glosario del resumen son el agregado del reductor web, no la metadatos del proveedor.

Se incluyen como máximo 500 ítems en orden de índice planeado, con un presupuesto combinado de elementos codificados de 512.000 bytes. Un elemento que no cabe es omitido, y `omitted_items` cuenta cada fila excluida por cualquiera de los límites. La salida traducida cruda, el texto en flujo, el pensamiento, las cargas de datos privadas del proveedor y los detalles crudos de fallo nunca son incluidos. Los conteos públicos de llamadas de modelo en directo pueden reiniciarse tras reconexión o reconciliación; los conteos finales duraderos y los estados de archivo son reconstruidos. Las instantáneas nativas completas están limitadas a 1.000.000 de bytes de JSON codificados. Si los metadatos de sesión inalterados o el resumen completo por sí solos superan ese límite, la unión falla con `{"reason":"payload_too_large"}` o un canal existente recibe `error` con esa razón y se cierra, en lugar de enviar un marco de tamaño excesivo o truncar silenciosamente la procedencia.

El servidor se suscribe al existente sesión inter-nodos PubSub **antes de** leer el prefijo durable, pliega la cola en vivo con deduplicación de secuencia y fusiona las notificaciones de progreso/estado/publicación en instantáneas completas a aproximadamente 100 ms. No se requiere consulta HTTP por cliente ni estado local del ejecutor. Cada cinco segundos, renueva la autorización y reconstruye el estado durable para reparar las notificaciones perdidas. Reconecte y se vuelva a unir después de llevar a primer plano o luego de una interrupción de transporte; la proyección de unión es suficiente sin reproducir deltas. Siga el ciclo de vida de latido normal de Phoenix mientras está conectado y abandone el tema cuando deje de verlo.

La concesión de token actual persistente, vencimiento/revocación, usuario, `translation:read` alcance de token, permisos de política, visibilidad del proyecto y asociación exacta de cuenta/proyecto/sesión se verifican en la unión y antes de cada instantánea. El alcance faltante o permiso de política devuelve `{"reason":"forbidden"}`; un recurso ausente devuelve `{"reason":"not_found"}`; la autenticación expirada/revocada devuelve `{"reason":"sign_in_required"}`. Tras una unión exitosa, la denegación emite `access_revoked` con esa razón y cierra inmediatamente el canal sin otra instantánea. La renovación también detecta revocación en canales inactivos. En `sign_in_required` actualice/re-autenticar y cree una nueva conexión; en otras denegaciones, deje de mostrar el detalle protegido. WebSockets son un mecanismo de actualización en vivo desde primer plano, no una garantía de entrega mientras la aplicación móvil está suspendida.

## Analítica

`GET /api/:handle/projects/:project/analytics?days=30` devuelve métricas de resumen, hasta diez páginas principales y la serie temporal del tráfico. Un proyecto vacío devuelve:

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

`days` tiene por defecto `30` y debe ser un entero de `1` a `365`. La ventana de reporte UTC en tiempo real termina en el momento de la solicitud. Estas son las mismas agregaciones de ClickHouse con alcance de proyecto que el tablero, incluyendo sus identificadores de visitante rotados a diario. Los fallos de almacenamiento devuelven `503` con `error: "analytics_unavailable"`, nunca métricas cero inventadas.

`traffic.granularity` es `"hour"` para ventanas de hasta dos días, `"day"` para ventanas de hasta noventa días y `"month"` en otro caso. `traffic.points` es cronológico. Cada punto contiene un timestamp UTC de inicio de bucket y conteos de enteros no negativos:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Los conteos incluyen solo eventos en la ventana de reporte solicitada, por lo que el primer y último bucket pueden ser parciales. Cuando existen eventos, los buckets silenciosos en esa ventana se incluyen con conteos cero. Cuando no existen eventos, `points` está vacío en lugar de una tendencia plana sintética. `unique_visitors` cuenta identificadores únicos **dentro de cada bucket**; sumar estos valores no da el conteo de visitantes únicos del período. Use `summary.unique_visitors` para ese total. Los clientes deben trazar los buckets devueltos sin cambios en lugar de reconstruir una tendencia a partir de métricas de resumen.

## Conversaciones Toki

### Crear y listar

`POST /api/:handle/projects/:project/toki/conversations` acepta un UUID generado por el cliente:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Devuelve `201` con `{conversation, messages: []}`. Las conversaciones vacías tienen título `New conversation` y estado `completed` (inactivo, no generando). Reproducir el mismo UUID para el mismo actor, proyecto y origen devuelve el detalle existente sin crear otra conversación. Reutilizarlo para otro actor, proyecto o origen devuelve `409` con `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` devuelve `{conversations: [...], meta: {...}}`. Una conversación contiene `id`, `title`, `status`, `updated_at`, nulo `error` y nulo `translation_session_id`. Los títulos se derivan del primer mensaje del usuario, no de una segunda llamada al modelo.

### Origen de traducción

La creación acepta opcionalmente un UUID de sesión de traducción del mismo proyecto:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

El origen es inmutable; la omisión y `null` también significan sin origen. Una reintentación debe suministrar el mismo origen, incluyendo después de enviar mensajes. No puede adjuntar un origen posteriormente ni removerlo con un reintentado. Un origen malformado devuelve `422`; una fuente ausente o de proyecto extranjero devuelve `404`. La creación vinculada a una fuente adicionales requer `translation:read` alcance de token y permiso de política actual, junto con `toki:write` y permiso de lectura de proyecto. Las sumarios de fuente, metadatos, roles y propiedad suministrados por el cliente son ignorados. Solo el UUID se consolida; el servidor resuelve su contexto autorizado en el momento de la respuesta.

**Conversaciones vinculadas a una fuente fallan en modo cerrado**, en lugar de simplemente redactar el UUID: sin `translation:read` alcance de token actual o permiso de política, detalle, reproducir creación de origen coincidente, envío de mensaje y reproducción de mensaje devuelven `403`. Un origen incompatible aún devuelve `409` sin devolver historial o metadatos de fuente. Las listas omiten la conversación vinculada a una fuente completa, incluido su título y contribución a los conteos de paginación. Esto protege los mensajes anteriores del asistente que podrían mencionar la fuente. Los alcances faltantes incluyen el desafío normal `WWW-Authenticate`. Las conversaciones desvinculadas mantienen su comportamiento de autorización existente solo de Toki.

Fuentes eliminadas o movidas también fallan en modo cerrado: detalles vinculados a fuentes, envíos y reintentos de creación coincidente devuelven `404`, y las listas omiten la conversación. El UUID inmutable permanece almacenado después de la eliminación de la fuente para que un reintentado no pueda volverse desvinculado silenciosamente. La referencia no tiene una clave extraña cascada; cada uso comprueba la existencia actual de la fuente y su proyecto/cuenta exacta. Ninguna referencia de fuente otorga acceso ni cambia una voz, glosario o contexto compartido.

Crear o abrir una conversación vinculada a una fuente **no** envía un mensaje ni encola la inferencia. La navegación nativa debería obtener primero el detalle de traducción; solo una acción explícita del usuario debe crear la conversación, y un envío de mensaje explícito separado inicia una vuelta. No se proporciona publicación de propuesta, revisión de discusión compartida ni herramientas de redacción de agente.

### Enviar y consultar

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` acepta un UUID de **mensaje** generado por el cliente separado:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La solicitud consolida el mensaje del usuario y un trabajo Oban en una única transacción de base de datos. No llama a un modelo. Devuelve `202` con estado de conversación `queued` y los mensajes actuales. Consulte `GET /api/:handle/projects/:project/toki/conversations/:id` mientras el estado sea `queued` o `running`; deténgase en `completed` o `failed`.

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

Los mensajes tienen rol `user` o `assistant` y son cronológicos. Una conversación contiene a lo sumo 100 mensajes, por lo que el punto de detalle devuelve su historial completo acotado sin una solicitud de página adicional.

Reintentar un UUID de mensaje con contenido idéntico nunca encola otra inferencia, incluso tras la finalización o el error. Un reintentado resuelto devuelve `200`; un reintento pendiente devuelve `202`. Reutilizar un UUID con contenido diferente o en otra conversación devuelve `409`. Enviar un mensaje diferente mientras se produce una vuelta devuelve `409` con `error: "conversation_busy"`.

### Comportamiento del modelo y límites

- Cada mensaje del usuario es texto no en blanco, a lo sumo 8.000 caracteres y 32.000 bytes UTF-8. UUIDs, tipos o contenido inválidos devuelven `422`.
- Cada usuario puede mantener a lo sumo 100 conversaciones por proyecto y cinco conversaciones en cola/ejecución entre proyectos. Más de cinco vueltas pendientes devuelve `429`; los límites de conversación/historial devuelven `422`.
- Los nuevos mensajes están limitados a 30 por hora por usuario por servidor, además de los límites de velocidad de API normales. Los reintentos no consumen cuota de inferencia.
- La cola dedicada Oban ejecuta dos trabajos concurrentemente por servidor. Cada vuelta realiza un máximo de una solicitud HTTP del proveedor: ReqLLM prepara la solicitud del proveedor, luego el trabajador Oban la ejecuta síncronamente con reintentos HTTP y redirecciones deshabilitadas después del acoplamiento del proveedor. No hay sesiones de Condukt, tareas de inferencia desvinculadas, herramientas, agentes subordinados o carga de instrucciones del sistema de archivos. El proveedor recibe un límite de 2.048 tokens de salida; las respuestas del asistente también están limitadas a 8.000 caracteres y 32.000 bytes.
- Las conexiones HTTP y las esperas de pool están limitadas a cinco segundos y las esperas de recepción de socket a sesenta segundos. El trabajador Oban tiene un plazo duro de reloj de pared de noventa segundos, incluidas las respuestas gota a gota. La terminación del trabajador también termina su ejecución local de inferencia. Desconectarse no puede garantizar la cancelación de la computación ya aceptada por un proveedor remoto, por lo que los fallos ambiguos nunca se reintentan automáticamente.
- El modelo recibe metadatos de proyecto acotados y a lo sumo tres resúmenes de traducción recientes cuando tanto el token como la membresía actual permiten `translation:read`. Los últimos diez extractos de conversación están acotados independientemente del almacenamiento. No tiene capacidades de escritura ni acceso general al repositorio, y no se suministran análisis al modelo.
- Para una conversación vinculada a una fuente, el modelo recibe además la fuente exacta persistente, incluso aunque no sea reciente: UUID, estado, metadatos del commit, idiomas, conteo y a lo sumo 1.000 caracteres de resumen. El contexto está etiquetado `provenance: "session_summary"`, y el prompt requiere informar esta limitación a nivel de resumen. No se cargan texto de segmentos, archivos del repositorio o contexto de fuente suministrado por el cliente.
- Las credenciales se resuelven a través del modelo generativo existente de la cuenta y la configuración de inferencia del servidor. No se utilizan sesiones interactivas CLI/OAuth para Toki. Credenciales faltantes o no soportadas producen estado `failed` con `error: "provider_unavailable"`.
- Los fallos del proveedor producen `inference_failed`; la salida vacía o de tamaño excesivo produce `invalid_provider_response`. No se devuelven errores crudos del proveedor ni secretos. No se inserta ninguna respuesta sintética del asistente ante el fallo.
- El acceso a cuenta/proyecto y la existencia de la fuente, la asociación proyecto/cuenta y la autorización de traducción se comprueban nuevamente antes y después de la inferencia. El acceso revocado o los alcances en cola insuficientes provocan el fallo de la vuelta con `not_authorized`; una fuente eliminada o movida falla con `source_unavailable`. No se persiste ninguna respuesta del asistente ante cualquiera de los fallos.
- Un trabajo de recuperación se ejecuta cada minuto y marca el trabajo en ejecución con más de dos minutos, o el trabajo en cola con más de quince minutos, como `failed` con `inference_interrupted`. Esto resuelve trabajos cronometrados, terminados y huérfanos sin reintentar la inferencia. Un trabajo retrasado no puede reclamar un mensaje caducado ni sobrescribir una vuelta más reciente. Un usuario puede intencionadamente enviar un **nuevo** UUID de mensaje después de un fallo.

## Errores

`401` significa que la autenticación falló. `403` significa que el alcance o la política de recursos negó el acceso; los alcances faltantes incluyen un `WWW-Authenticate` desafío. Desconocidos proyectos y UUIDs de conversación extranjeros/privados devuelven `404`. La validación usa `422`, la paginación usa `400`, los conflictos de UUID/ocupación usan `409` y el agotamiento de cuota usa `429`.
