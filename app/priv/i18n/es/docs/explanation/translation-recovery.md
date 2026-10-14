%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene el Markdown intacto y se recupera de la limitación por parte de los proveedores y las traducciones interrumpidas.",
  category: "Explicación",
  section: "translation",
  order: 8
}
---

Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva ese requisito: un reintento debe aún preservar la estructura de la fuente y los marcadores de posición requeridos, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Parsed source only to find its prose: paragraphs, headings, list items, table cells, the reader-facing attributes of components and HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), and the text of an HTML `<summary>`. Each translation is written back into the exact bytes its source occupied, so code, link destinations, components, GitHub alerts, explicit heading anchors such as `{#install}`, list markers, and blank lines stay byte-for-byte identical.

Cada párrafo o encabezado se traduce como una oración completa. El formato en línea se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras vinculadas o enfatizadas, y `<gN/>` para contenido que no debe cambiar, como código en línea o un componente. El modelo puede mover etiquetas para seguir el orden de palabras del idioma objetivo, pero debe mantener cada etiqueta exactamente una vez. Cada solicitud también transporta el documento fuente circundante y las traducciones más recientes del mismo archivo, para referencia.

Una unidad que elimina o inventa una etiqueta se envía nuevamente por su cuenta, con el motivo, hasta tres veces. Las unidades que volvieron válidas se conservan. Después de unir, Glossia analiza el resultado y compara su estructura con la fuente. Una traducción que se convertiría en un encabezado, lista o énfasis por sí sola tiene su proído escapada, lo cual no necesita ninguna llamada al modelo adicional.

## Traducción de catálogos

Los catálogos Gettext se analizan en cadenas antes de la traducción. Las solicitudes portan como máximo ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena más grande permanece intacta. El modelo devuelve una matriz con el mismo número de cadenas en el mismo orden. Glossia comprueba las variables de interpolación y rechaza traducciones vacías.

Los encabezados se construyen en código utilizando las reglas de plural del idioma objetivo. Los identificadores de mensajes de la fuente, los comentarios y la estructura del catálogo provienen de la fuente analizada. Si un lote devuelve contenido malformado, Glossia lo reintenta una vez y luego lo divide en lotes más pequeños. Los lotes adyacentes exitosos no necesitan ser traducidos nuevamente.

## Limitación del proveedor

Glossia coordina solicitudes de traducción que utilizan la misma credencial y modelo. Una respuesta de limitación de tasa extiende su tiempo de espera compartido y aumenta el espacio entre nuevas solicitudes. El tráfico exitoso reduce gradualmente ese espacio después de un minuto sin limitación. Las solicitudes ya en ejecución se permiten finalizar.

Las pistas de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el retraso de la reversa, hasta un retraso base de 30 segundos más jitter; la pista más larga del proveedor tiene prioridad, limitada a cinco minutos. El encabezado `x-ratelimit-reset` de Together es reconocido junto con `retry-after`.

Después de ocho intentos de solicitud no exitosos, la ejecución del repositorio deja de iniciar nuevos archivos. Una continuación demorada hereda la rama de traducción y reanuda su trabajo inacabado. El intento anterior permanece visible en el historial de sesión, vinculado a través de la continuación. Los retrasos aumentan de un minuto a cinco minutos, con un máximo de seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y las sesiones canceladas nunca se restauran. Los fallos de validación por sí solos no programan la recuperación del proveedor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción por lotes: un commit por cada 25 archivos, o cada 15 minutos, y un commit final cuando la ejecución termina. Cada push ejecuta las comprobaciones de solicitud de extracción del repositorio, por lo que el agrupamiento evita que una ejecución grande inicie una ejecución de comprobación por archivo. Un proyecto tiene una sola solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa la abierta, y solo traduce lo que ha cambiado desde entonces. Una vez que esa solicitud de extracción se fusiona o cierra, la siguiente ejecución inicia una nueva. Dentro de archivos inacabados, los segmentos validados localmente y los lotes de recuperación también se guardan en la base de datos durante siete días. Estos puntos de control sobreviven si un proceso de trabajo se detiene. Se limita a la cuenta, al proyecto, a la entrada del documento, a la credencial y al modelo efectivos, al contexto y al intento de segmento o reparación.

Una ejecución reanudada solo puede reutilizar un segmento cuando sus entradas aún coinciden. Siempre valida nuevamente el documento ensamblado final. Las respuestas del modelo rechazadas no son puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado porque el validador puede no identificar un segmento responsable único.

Los puntos de control caducados y los registros de ritmo inactivos del proveedor se eliminan por el trabajador de recuperación de sesiones programado. Estos son registros de operaciones; los usuarios no necesitan agregarlos a su repositorio o configurarlos en `L10N.md`.
