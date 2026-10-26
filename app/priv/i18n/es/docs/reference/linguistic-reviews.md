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

Las corridas de traducción del repositorio con un modelo de decisión configurado pueden solicitar entrada lingüística por significado de origen ausente o contexto de dominio, orientación conflictiva, o adaptación cultural derivada. La poca confianza por sí sola no dispara una pregunta. Los errores corregibles desde el contexto existente utilizan el presupuesto de corrección habitual; los fallos de calidad que permanezcan tras ese presupuesto también pueden solicitar entrada. Sin un modelo de decisión, el escalado lingüístico automático está desactivado.

Solo el archivo/localización afectado se detiene. Su candidato no aprobado no se publicará. Los archivos independientes completan y pueden publicarse normalmente. Tras finalizar la publicación, la sesión se convierte en `awaiting_input` y libera su ejecutor. No consume un trabajador mientras una persona responde.

Cada escalación abre una **conversación compartida de Toki con un objetivo lingüístico definido**, enlazada a la sesión de traducción. Los participantes discuten el significado, hacen preguntas de seguimiento y refinan una decisión propuesta. El debate por sí solo nunca aprueba una traducción ni escribe contexto del repositorio. Las conversaciones ordinarias de Toki permanecen privadas para su propietario, incluso para los administradores.

Todos los actuales miembros autorizados cuyos idiomas fluentes declarados coinciden con la localización objetivo son invitados a la misma conversación. La competencia lingüística es separada del idioma de visualización y no otorga acceso al proyecto ni permiso para aprobar decisiones. Un idioma amplio como `es` coincide con variantes regionales como `es-MX`; los scripts explícitos incompatibles no coinciden. Declaraciones regionales como `zh-TW` usan su script CLDR habitual, mientras `zh` amplio permanece sin restricciones de script.

Los participantes elegibles reciben notificaciones push móviles genéricas solo cuando han optado; la entrega comprueba la fluencia actual, membresía, acceso al proyecto y el objetivo abierto. Las notificaciones abre la conversación compartida. Las conversaciones y aprobaciones están disponibles desde ambas aplicaciones nativas y el panel de control web. Consulte [Notificaciones push nativas](/docs/reference/native-push-notifications) para la configuración del proveedor y la política de entrega.

## Perfil de idioma competente

`GET /api/me` incluye `user.fluent_languages`. `PUT /api/me/fluent-languages` requiere `user:write` y acepta solo `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Sustituye la lista del usuario autenticado y devuelve el sobre del perfil. Las etiquetas CLDR BCP47 admitidas mantienen la especificidad regional/script explícita y usan mayúsculas canónicas; los duplicados se colapsan. Un array vacío limpia la fluencia. Las etiquetas inválidas, campos no relacionados o más de 50 entradas enviadas devuelven 422. Esto nunca cambia la localización UI.

## API de Revisión

El `GET /api/:handle/projects/:project/translations/:id/reviews` requiere `translation:read` y acceso al proyecto. Devuelve `{"reviews": [...]}`, con preguntas abiertas primero y luego las más antiguas, limitado a 500 entradas. Refresque después de responder para revelar cualquier pregunta restante; el historial respondido nunca oculta una pregunta abierta detrás del límite.

Cada revisión incluye `id`, `translation_session_id`, `conversation_id`, `participants` (`id` y `name` nullable), `status`, `source_path`, `output_path`, `locale`, `question`, `source_excerpt` y `translation_excerpt` limitados, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, y `inserted_at`. El estado es `open`, `answered` o `stale`.

`answered_by` identifica a la persona que aprobó la decisión como `{"id": "<user UUID>", "name": "<current display name>"}`; `name` puede ser null. Este campo es null antes de la aprobación o cuando el aprobador no está disponible. No contiene correo electrónico ni otros campos privados de perfil, y la repetición de una aprobación no cambia al aprobador. Este mismo campo se incluye en el `linguistic_review` anidado en las conversaciones de Toki compartidas. No se expone ninguna marca de tiempo de aprobación; `inserted_at` es el tiempo de creación de la revisión, no su tiempo de aprobación.

Utilice los endpoints de conversación y mensajes de proyecto Toki existentes para la discusión. Las conversaciones de objetivos compartidos aparecen junto a las conversaciones privadas del actor en el historial de Toki. El historial compartido requiere permiso actual de política de lectura/escritura de Toki y acceso a lectura de traducción; el historial ordinario permanece solo para el propietario. Los mensajes humanos incluyen su identidad de autor, y las respuestas incluyen `status` y `reply_to_id`. Toki recibe fragmentos de origen/candidato limitados y el objetivo, no el acceso de escritura al repositorio.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` requiere tanto `translation:read` como `translation:write` más acceso al proyecto:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

El `resolution_message_id` debe identificar la última respuesta del asistente **respuesta** completada en la conversación del objetivo, no su pregunta inicial. `answer` es la decisión aprobada por el humano y es requerida y no vacía. `guidance` y `context_scope` son opcionales; el alcance predeterminado es `locale` y también puede ser `project`. La respuesta y la orientación permiten hasta 8,000 caracteres y 32,000 bytes UTF-8 cada una. La orientación no puede contener comentarios de marcador de revisión reservados de Glossia. El servidor elige los paths del repositorio; un path proveído por el cliente nunca se usa.

Una respuesta exitosa es `{"review": {...}}`. La repetición del mismo decisión, mensaje de resolución, orientación y alcance es idempotente. Una conversación ocupada devuelve `409 conversation_busy`; un mensaje nuevo o una referencia de resolución inválida devuelve `409 resolution_outdated`. Recargue y revise la discusión actual antes de aprobar de nuevo. Una decisión diferente en un objetivo resuelto devuelve `409 already_answered`; aprobar un objetivo cancelado o superado devuelve `409 stale`. Texto imposible o alcance no disponible devuelve 422. IDs faltantes y de proyecto extranjero devuelven 404. La autenticación normal y autorización del proyecto se aplica en cada solicitud, incluyendo reprocesos. Los objetivos cerrados rechazan mensajes de discusión nuevos con `409 goal_closed`.

## Continuaciones y contexto obsoleto

Las decisiones pueden aprobarse mientras el trabajo independiente aún se ejecuta. Nunca inician un segundo ejecutor entonces. Una vez que el ejecutor ha liberado y cada objetivo en esa ejecución está resuelto, Glossia colatea atómico una sesión de continuación. `resumed_session_id` la identifica; la sesión original permanece histórica `awaiting_input`. Tanto el panel de control como las conversaciones nativas vinculan a la continuación.

La continuación tiene una identidad de ejecución fresca y mantiene la rama de publicación de traducción y las salidas validadas. Cada respuesta aplica solo a la fuente idéntica y el sello de huella de contexto de traducción resuelto. Fuente, voz, glosario, modelo o instrucciones de repositorio cambiadas previenen el reuso de la respuesta. Un commit más reciente de rama por defecto sobrescribe las sesiones de espera y marca las preguntas abiertas como obsoletas. La cancelación también marca las preguntas abiertas como obsoletas.

## Orientación del repositorio reutilizable

La orientación reutilizable es una edición humana explícita y separada. Una respuesta por sí sola no se convierte en contexto del repositorio, y los transcritos de chat privados nunca se copian automáticamente.

`locale` apunta a la capa de localización aplicable, como `L10N/es.md`; `project` apunta al `L10N.md` aplicable.

La orientación se propone en la solicitud de extracción normal de traducción, sin escribirse silenciosamente a la rama principal por defecto. El repositorio aún debe coincidir con el resumen del contexto registrado; una edición conflictiva falla la publicación en lugar de sobrescribirla. Las rutas deben ser documentos de localización relativos al repositorio sin ascenso ni enlaces simbólicos. Cada documento de contexto está limitado a 1 MiB. Fusionar la solicitud de extracción convierte la orientación en un contexto de localización versiónado estándar para ejecuciones posteriores.
