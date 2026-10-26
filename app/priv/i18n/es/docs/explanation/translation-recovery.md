%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene Markdown intacto y recupera de la limitación del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  section: "translation",
  order: 8
}
---

Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva ese requisito: un reintento debe seguir conservando la estructura de origen y los marcadores de posición necesarios, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción de Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Solo parsea el origen para encontrar su prosa: párrafos, encabezados, elementos de lista, celdas de tabla, los atributos visibles al lector de componentes y HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), y el texto de un HTML `<summary>`. Cada traducción se escribe de nuevo en los mismos bytes que ocupaba su origen, por lo que el código, los destinos de enlace, los componentes, las alertas de GitHub, las anclas explícitas de encabezado como `{#install}`, los marcadores de lista y las líneas en blanco permanecen idéntico byte a byte.

Cada párrafo o encabezado se traduce como una oración completa. El formato en línea se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras vinculadas o enfatizadas, y `<gN/>` para el contenido que no debe cambiar, como código en línea o un componente. El modelo puede mover etiquetas para seguir el orden de palabras del idioma de destino, pero debe mantener cada etiqueta exactamente una vez. Cada solicitud también lleva el documento fuente circundante y las traducciones más recientes del mismo archivo, para referencia.

Una unidad que pierde o inventa una etiqueta se envía nuevamente por sí misma, con la razón, hasta tres veces. Las unidades que resultan válidas se conservan. Después de ensamblar, Glossia parsea el resultado y compara su estructura con la fuente. Una traducción que daría origen a un encabezado, lista o énfasis por sí sola tiene su prosa escapada, lo que no requiere más llamada de modelo.

## Traducción de catálogo

Los catálogos de Gettext se parsean en cadenas antes de la traducción. Las solicitudes transportan como máximo ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena más grande permanece intacta. El modelo devuelve un array con la misma cantidad de cadenas en el mismo orden. Glossia comprueba las variables de interpolación y rechaza las traducciones vacías.

Las cabeceras se construyen en código utilizando las reglas de plural del idioma de destino. Los identificadores de mensaje fuente, los comentarios y la estructura del catálogo provienen del origen parseado. Si un lote devuelve contenido malformado, Glossia lo reintenta una vez, luego lo divide en lotes más pequeños. Los lotes vecinos exitosos no necesitan ser traducidos nuevamente.

## Limitación del proveedor

Glossia coordina las solicitudes de traducción que usan la misma credencial y modelo. Una respuesta de límite de tasa extiende su tiempo de enfriamiento compartido y aumenta el espaciado entre las nuevas solicitudes. El tráfico exitoso reduce gradualmente ese espaciado después de un minuto sin limitación. Las solicitudes ya en ejecución tienen permiso para finalizar.

Las indicaciones de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el backoff, hasta un retraso base de 30 segundos más jitter; una indicación del proveedor más larga tiene precedencia, limitada a cinco minutos. El encabezado `x-ratelimit-reset` de Together se reconoce junto con `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio deja de comenzar nuevos archivos. Una continuación atrasada hereda la rama de traducción y reanuda su trabajo inacabado. El intento anterior permanece visible en el historial de la sesión, vinculado a través de la continuación. Los retrasos crecen desde un minuto hasta cinco minutos, con como máximo seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y las sesiones canceladas nunca se reviven. Los fallos de validación por sí solos no programan la recuperación del proveedor.

## Recuperación después de un lanzamiento de motor

Una sesión tiene dos versiones independientes: el commit del repositorio que se está traduciendo y la imagen del motor de traducción que lo ejecuta. En Kubernetes, cada trabajo fije el digest exacto de la imagen del réplica web que lo programó. Los trabajos sobreviven a los despliegues web y nunca cambian a mitad de código durante una traducción. Un trabajo programado justo antes de un despliegue por tanto puede finalizar en el motor anterior incluso después de que la aplicación web se haya actualizado. Los detalles de la sesión muestran el digest del motor; las sesiones anteriores sin este origen muestran «No registrado».

Cada cinco minutos, Glossia comprueba si su Despliegue se ha completado en su totalidad. Solo un trabajador de ese lanzamiento sano puede programar la recuperación del motor. Si la sesión más reciente de un proyecto fue cola antes de que ese despliegue se completara, se ejecutó en un digest de motor grabado más antiguo y falló después dentro de las últimas seis horas, Glossia puede crear una continuación en el lanzamiento actual. Usar el tiempo de cola también cubre trabajos que esperan capacidad y solo arrancan tras el despliegue. Un digest de imagen diferente por separado no activa reintentos de fallos comunes después de despliegues no relacionados. Los archivos completados y la solicitud de extracción abierta se mantienen; solo el trabajo inacabado se traduce nuevamente. Las continuaciones de lanzamiento en cola esperan mientras un despliegue esté en progreso, como máximo 15 minutos. Los fallos de API o permisos de Kubernetes detienen el lanzamiento con un error explícito en lugar de ser confundidos con un despliegue en curso.

La recuperación es deliberadamente estrecha: la sesión debe haber terminado con un fallo de validación de elemento registrado, y cada elemento fallido en su último intento debe informar un fallo de estructura Markdown, contenido preservado o unidad Markdown. Intentos interrumpidos o parcialmente cancelados no califican. Errores del proveedor, crédito agotado, credenciales rechazadas, fallos de publicación, errores de lectura de fuente, fallos de comando de validación externa y causas desconocidas no son reintentados por un despliegue. Sesiones exitosas, activas, canceladas, obsoletas o sin versión tampoco se tocan. Una sesión más reciente siempre gana, incluso si el usuario la canceló.

Una sesión obtiene como máximo una continuación en un lanzamiento de motor diferente, con como máximo tres continuaciones de lanzamiento en un linaje. Si el nuevo motor sigue fallando, no se reintenta nuevamente en esa misma imagen, incluso después de un rollback. El linaje conserva los digest de motor intentados anteriormente, y el lanzador los comprueba de nuevo antes de crear un trabajo en cola. Los límites de recuperación del proveedor existentes se preservan a través de las continuaciones de lanzamiento. Las etiquetas de imagen mutables y despliegues sin una identidad de lanzamiento configurada no habilitan la recuperación automática del motor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción por lotes: un commit por cada 25 archivos, o cada 15 minutos, y un commit final cuando termina la ejecución. Cada empuje ejecuta las comprobaciones de la solicitud de extracción del repositorio, por lo que el agrupamiento evita que una ejecución grande inicie una comprobación por archivo. Un proyecto tiene una única solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa la que está abierta y solo traduce lo que cambió desde entonces. Una vez que esa solicitud de extracción se fusiona o se cierra, la siguiente ejecución inicia una nueva. Dentro de los archivos no terminados, los segmentos validados localmente y los lotes de recuperación también se guardan en la base de datos durante siete días. Estos puntos de control superviven si un proceso de trabajador se detiene. Están delimitados a la cuenta, proyecto, entrada de documento, credencial y modelo efectivos, contexto, y segmento o intento de reparación.

Una ejecución reanudada solo puede reutilizar un segmento cuando sus entradas aún coinciden. Siempre valida nuevamente el documento final compuesto. Las respuestas rechazadas del modelo no son puntos de control. Un fallo de validación de nivel de documento inicia un intento de reparación separado porque el validador puede no identificar un solo segmento responsable.

Los puntos de control expirados y los registros de ritmo del proveedor inactivos se eliminan por el trabajador de recuperación de sesión programado. Estos son registros operativos; los usuarios no necesitan añadirlos a su repositorio o configurarlos en `L10N.md`.
