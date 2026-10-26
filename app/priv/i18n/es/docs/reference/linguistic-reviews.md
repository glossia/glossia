%{
  title: "Revisiones lingüísticas",
  summary:
    "Decisiones humanas vinculadas a la fuente, continuaciones de traducción y orientación revisada del repositorio.",
  category: "Referencia",
  section: "translation",
  order: 31
}
---

## Escalación

Ejecuciones de traducción del repositorio con un modelo de decisión configurado pueden solicitar entrada lingüística para significados fuente faltantes o contexto de dominio, orientación conflictiva o adaptación cultural consecuente. La baja confianza por sí misma no dispara una pregunta. Los errores correctibles a partir del contexto existente utilizan el presupuesto de corrección ordinaria; los fallos de calidad remanentes tras ese presupuesto también pueden solicitar entrada. Sin un modelo de decisión, el escalado lingüístico automático se deshabilita.

Solo el archivo/idoma afectado se detiene. Su candidato sin aprobar no se publica. Los archivos independientes se completan y pueden publicarse normalmente. Tras finalizar la publicación, la sesión se vuelve `awaiting_input` y libera su ejecutor. No consume un trabajador mientras un humano responde.

Cada escalación abre una **conversación compartida de Toki con un objetivo lingüístico definido**, vinculada a la sesión de traducción. Los participantes discuten el significado, hacen preguntas de seguimiento y refinan una decisión propuesta. La discusión por sí sola nunca aprueba una traducción ni escribe contexto del repositorio. Las conversaciones ordinarias de Toki permanecen privadas para su propietario, incluso de los administradores.

Todos los compañeros autorizados actualmente cuya lengua fluente declarada coincide con el idoma destino son invitados a la misma conversación. La fluidez está separada del idioma de visualización y no otorga acceso al proyecto ni permisos para aprobar decisiones. Un idioma genérico como `es` coincide con variantes regionales tales como `es-MX`; los guiones explícitos incompatibles no coinciden. Las declaraciones regionales como `zh-TW` utilizan su guion CLDR habitual, mientras que `zh` genérico permanece sin restricciones de guion.

Los participantes elegibles reciben notificaciones push móviles genéricas solo cuando han optado por ello; el repeso de entrega verifica la fluidez actual, membresía, acceso al proyecto y el objetivo abierto. Las notificaciones abren la conversación compartida. Las conversaciones y aprobaciones están disponibles desde ambas aplicaciones nativas y el panel de control web. Consulte [Notificaciones push nativas](/docs/reference/native-push-notifications) para configuración del proveedor y política de entrega.

## Perfil de idioma fluente

`GET /api/me` incluye `user.fluent_languages`. `PUT /api/me/fluent-languages` requiere `user:write` y solo acepta `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Reemplaza la lista del usuario autenticado y devuelve la bandera de perfil. Las etiquetas CLDR BCP47 compatibles retienen la especificidad de región/guion explícita y usan mayúsculas canónicas; los duplicados se colapsan. Un array vacío limpia la fluidez. Etiquetas inválidas, campos no relacionados o más de 50 registros enviados devuelven 422. Esto nunca cambia el idoma de interfaz de usuario.

## API de revisión

`GET /api/:handle/projects/:project/translations/:id/reviews` requiere `translation:read` y acceso al proyecto. Devuelve `{"reviews": [...]}`, con preguntas abiertas primero y luego las más antiguas primero, limitado a 500 entradas. Actualice después de responder para revelar cualquier pregunta restante; el historial respondido nunca oculta una pregunta abierta detrás del límite.

Cada revisión incluye `id`, `translation_session_id`, `conversation_id`, `participants` (`id` y `name`), `status`, `source_path`, `output_path`, `locale`, `question`, `source_excerpt` y `translation_excerpt` acotados, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id` y `inserted_at`. El estado es `open`, `answered` o `stale`.

Utilice los puntos finales de conversación y mensaje del proyecto Toki existentes para discutir. Las conversaciones de objetivos compartidos aparecen junto a las conversaciones privadas del actor en el historial de Toki. Los historiales compartidos requieren permiso actual de política de lectura/escritura de Toki y acceso de lectura de traducción; los historiales ordinarios permanecen solo para el propietario. Los mensajes de humanos incluyen su identidad de autor y las respuestas incluyen `status` y `reply_to_id`. Toki recibe extractos de entrada/candidato acotados y el objetivo, no acceso de escritura del repositorio.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` requiere tanto `translation:read` y `translation:write`, más acceso al proyecto:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` debe identificar la **respuesta** asistente completada más reciente en la conversación de objetivos, no su pregunta de apertura. `answer` es la decisión aprobada por humanos y es requerida y no en blanco. `guidance` y `context_scope` son opcionales; el ámbito predetermina a `locale` y puede ser también `project`. Respuesta y orientación permiten hasta 8.000 caracteres y 32.000 bytes UTF-8. La orientación no puede contener comentarios de marcador de revisión reservados de Glossia. El servidor elige rutas del repositorio; una ruta suministrada por cliente nunca se usa.

Una respuesta exitosa es `{"review": {...}}`. Volver a ejecutar la misma decisión, mensaje de resolución, orientación y ámbito es idempotente. Una conversación ocupada devuelve `409 conversation_busy`; un mensaje más reciente o referencia de resolución inválida devuelve `409 resolution_outdated`. Recargue y revise la discusión actual antes de aprobar de nuevo. Una decisión diferente en un objetivo resuelto devuelve `409 already_answered`; aprobar un objetivo cancelado o sustituido devuelve `409 stale`. Texto inválido o ámbito no disponible devuelve 422. IDs faltantes y de proyecto extranjero devuelven 404. Autenticación normal y autorización de proyecto aplican en cada solicitud, incluyendo reejecuciones. Objetivos cerrados rechazan nuevos mensajes de discusión con `409 goal_closed`.

## Continuaciones y contexto vencido

Las decisiones se pueden aprobar mientras el trabajo independiente aún se ejecuta. Nunca inician un segundo ejecutor entonces. Una vez que el ejecutor se ha liberado y todos los objetivos en esa ejecución están resueltos, Glossia pone en cola una sesión de continuación atómicamente. `resumed_session_id` lo identifica; la sesión original permanece histórica `awaiting_input`. Tanto el panel de control como las conversaciones nativas vinculan a la continuación.

La continuación tiene una identidad de ejecución fresca y retiene la rama de publicación de traducción y los resultados validados. Cada respuesta solo se aplica a la fuente idéntica y huella digital de contexto de traducción resuelto. Fuente cambiada, voz, glosario, modelo o instrucciones del repositorio evitan la reutilización de respuestas. Un commit en la rama predeterminada más reciente sustituye a las sesiones de espera y marca como obsoletas las preguntas abiertas. La cancelación también marca como obsoletas las preguntas abiertas.

## Orientación reproducible del repositorio

La orientación reproducible es una edición humana explícita e independiente. Una respuesta por sí sola no se convierte en contexto del repositorio y los transcripciones de chat privadas nunca se copan automáticamente.

`locale` orienta a la capa de idioma aplicable, como `L10N/es.md`; `project` orienta al `L10N.md` aplicable. Los archivos de contexto con alcance existente se respetan. Las capas de idioma faltantes reciben su frontmatter de idioma. El frontmatter y el texto existente se preservan, y cada decisión se adjunta con su UUID de revisión para procedencia e idempotencia.

Se propone la orientación en la solicitud de extracción de traducción normal, no se escribe silenciosamente en la rama predeterminada. El repositorio debe seguir coincidiendo con el resumen del contexto registrado; una edición conflictiva falla la publicación en lugar de sobrescribirlo. Las rutas deben ser documentos de localización relativos al repositorio sin recorrido ni enlaces simbólicos. Cada documento de contexto tiene un límite de 1 MiB. Fusionar la solicitud de extracción convierte la orientación en un contexto de localización versionado ordinario para futuras ejecuciones.
