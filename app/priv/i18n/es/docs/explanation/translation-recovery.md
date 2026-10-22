%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene el Markdown intacto y se recupera de la limitación del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  section: "translation",
  order: 8
}
---

Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva ese requisito: un reintento debe seguir conservando la estructura del origen y los marcadores de posición requeridos, y cada archivo ensamblado pasa sus comandos configurados de validación.

## Traducción de Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Analiza el origen solo para encontrar su prosa: párrafos, encabezados, elementos de lista, celdas de tabla, los atributos dirigidos al usuario de componentes y HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), y el texto de un HTML `<summary>`. Cada traducción se escribe de nuevo en los bytes exactos que ocupaba su origen, para que el código, los destinos de enlace, los componentes, las alertas de GitHub, los anclajes de encabezado explícitos como `{#install}`, los marcadores de lista y las líneas en blanco permanezcan idénticos byte a byte.

Cada párrafo o encabezado se traduce como una oración completa. El formato en línea se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras enlazadas o enfatizadas, y `<gN/>` para el contenido que no debe cambiar, como el código en línea o un componente. El modelo puede mover las etiquetas para seguir el orden verbal de la lengua objetivo, pero debe mantener cada etiqueta exactamente una vez. Cada solicitud también lleva el documento fuente circundante y las traducciones más recientes del mismo archivo, como referencia.

Una unidad que elimina o inventa una etiqueta se envía nuevamente por sí sola, con la razón, hasta tres veces. Las unidades que devolvieron válido se mantienen. Después de ensamblar, Glossia analiza el resultado y compara su estructura con el origen. Una traducción que por sí sola se convertiría en un encabezado, lista o énfasis tiene su prosa escapada, lo cual no requiere otra llamada al modelo.

## Traducción de catálogo

Los catálogos de Gettext se analizan en cadenas antes de la traducción. Las solicitudes llevan como máximo ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena más grande se mantiene intacta. El modelo devuelve un array con el mismo número de cadenas en el mismo orden. Glossia comprueba las variables de interpolación y rechaza traducciones vacías.

Los encabezados se construyen en el código usando las reglas de plural del idioma objetivo. Los identificadores de mensaje fuente, los comentarios y la estructura del catálogo provienen del origen analizado. Si un lote devuelve contenido mal formado, Glossia intenta nuevamente una vez, luego lo divide en lotes más pequeños. Los lotes vecinos exitosos no necesitan ser traducidos nuevamente.

## Limitación del proveedor

Glossia coordina las solicitudes de traducción que usan la misma credencial y modelo. Una respuesta de límite de tasa extiende su periodo de enfriamiento compartido y aumenta el espacio entre las nuevas solicitudes. El tráfico exitoso reduce gradualmente ese espacio después de un minuto sin limitación. Se permite que las solicitudes en ejecución finalicen.

Las indicaciones de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el backoff, hasta un retraso base de 30 segundos más jitter; una indicación del proveedor más larga tiene prioridad, con un límite de cinco minutos. El encabezado de Together `x-ratelimit-reset` se reconoce junto con `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio se detiene de iniciar nuevos archivos. Una continuación diferida hereda la rama de traducción y reanuda su trabajo inacabado. El intento anterior permanece visible en el historial de sesión, vinculado a través de la continuación. Los retrasos aumentan desde un minuto hasta cinco minutos, con un máximo de seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y las sesiones canceladas nunca se reactivan. Los fallos de validación por sí solos no programan la recuperación del proveedor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción en lotes: un commit cada 25 archivos, o cada 15 minutos, y un commit final cuando termina la ejecución. Cada push ejecuta las comprobaciones de solicitud de extracción del repositorio, por lo que la agrupación evita que una gran ejecución inicie una comprobación por archivo. Un proyecto tiene una sola solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa la abierta y solo traduce lo que cambió desde entonces. Una vez que esa solicitud de extracción se fusiona o cierra, la siguiente ejecución inicia una nueva. Dentro de los archivos inacabados, los segmentos validados localmente y los lotes de recuperación también se guardan en la base de dados por siete días. Estos puntos de control superviven a la parada de un proceso trabajar. Están delimitados a la cuenta, proyecto, entrada de documento, credencial y modelo efectivos, contexto y segmento o intento de reparación.

Una ejecución reanudada puede reutilizar un segmento solo cuando sus entradas aún coinciden. Siempre valida el documento ensamblado final nuevamente. Las respuestas del modelo rechazadas no son puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado porque el validador puede no identificar un solo segmento responsable.

Los puntos de control caducados y los registros de ritmo de proveedor inactivos son eliminados por el trabajador de recuperación de sesiones programado. Son registros operativos; los usuarios no necesitan agregarlos a su repositorio ni configurarlos en `L10N.md`.
