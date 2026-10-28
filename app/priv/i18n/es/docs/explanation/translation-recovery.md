%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene el Markdown intacto y se recupera de la ralentización del proveedor y de las traducciones interrumpidas.",
  category: "explicación",
  section: "translation",
  order: 8
}
---

Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva ese requerimiento: un reintento debe aún preservar la estructura del origen y los marcadores de posición requeridos, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción de Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Solo analiza el origen para encontrar su contenido: párrafos, encabezados, elementos de lista, celdas de tabla, los atributos orientados al lector de componentes y HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), y el texto de un `<summary>` HTML. Cada traducción se vuelve a escribir en los bytes exactos que ocupaba su origen, por lo que el código, los destinos de enlace, los componentes, las alertas de GitHub, los anclajes explícitos de encabezado como `{#install}`, los marcadores de lista y las líneas en blanco permanecen idénticos, byte a byte.

Cada párrafo o encabezado se traduce como una oración completa. El formato en línea se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras enlazadas o enfatizadas, y `<gN/>` para contenido que no debe cambiar, como código en línea o un componente. El modelo puede mover las etiquetas para seguir el orden de palabras del idioma objetivo, pero debe mantener cada etiqueta exactamente una vez. Cada solicitud también lleva el documento fuente circundante y las traducciones más recientes del mismo archivo, para referencia.

Una unidad que elimina o inventa una etiqueta se envía nuevamente por separado, con el motivo, hasta tres veces. Se mantienen las unidades que resultaron válidas. Después de la unión, Glossia analiza el resultado y compara su estructura con el origen. Una traducción que se convirtiera por sí sola en un encabezado, lista o énfasis tiene su contenido escapado, lo cual no requiere otra llamada al modelo.

## Traducción de catálogo

Los catálogos Gettext se公报an en cadenas antes de la traducción. Las solicitudes llevan como máximo ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena más grande se mantiene íntegra. El modelo devuelve un array con el mismo número de cadenas en el mismo orden. Glossia comprueba las variables de interpolación y rechaza las traducciones vacías.

Los encabezados se construyen en código usando las reglas de plural del idioma objetivo. Los identificadores de mensajes fuente, los comentarios y la estructura del catálogo provienen del origen analizado. Si un lote devuelve contenido malformado, Glossia lo reintenta una vez, luego lo divide en lotes más pequeños. Los lotes vecinos exitosos no necesitan ser traducidos nuevamente.

## Limitación del proveedor

Glossia coordina las solicitudes de traducción que usan la misma credencial y modelo. Una respuesta de límite de tasa extiende su tiempo de enfriamiento compartido e incrementa la separación entre nuevas solicitudes. El tráfico exitoso reduce gradualmente esa separación tras un minuto sin limitación. Las solicitudes que ya están corriendo se permiten terminar.

Las pistas de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el backoff, hasta un retraso base de 30 segundos más jitter; una pista del proveedor más larga tiene prioridad, limitada a cinco minutos. El encabezado `x-ratelimit-reset` de Together se reconoce junto a `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio deja de iniciar nuevos archivos. Una continuación retrasada hereda la rama de traducción y reanuda su trabajo inconcluso. El intento anterior permanece visible en el historial de sesiones, vinculado a través de la continuación. Los retrasos aumentan de un minuto a cinco minutos, con un máximo de seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y las sesiones canceladas nunca se Reactivan. Los fallos de validación solos no programan la recuperación del proveedor.

## Recuperación tras un lanzamiento del motor

**Edición: Enterprise.** Las comprobaciones de despliegue de Kubernetes y la recuperación tras un lanzamiento del motor descritas en esta sección requieren [ejecutores de traducción aislados](/es/docs/reference/isolated-translation-runners). Community conserva la recuperación de Markdown, catálogos y proveedores, y el progreso persistente descritos en el resto de esta página.

Una sesión tiene dos versiones independientes: el commit del repositorio que se traduce y la imagen del motor de traducción que la ejecuta. En Kubernetes, cada trabajo fija el digest exacto de la imagen del réplica web que la programó. Los trabajos sobreviven a los despliegues web y nunca cambian el código a mitad de una traducción. Un trabajo programado justo antes de un despliegue puede finalizar en el motor anterior incluso después de que se haya actualizado la aplicación web. Los detalles de la sesión muestran el digest del motor; las sesiones más antiguas sin este origen muestran "No registrado."

Cada cinco minutos, Glossia comprueba si su despliegue se ha desplegado por completo. Solo un trabajador de ese lanzamiento sano puede programar la recuperación del motor. Si la sesión más reciente de un proyecto se colocó en cola antes de que ese despliegue se completara, se ejecutó en un digest del motor anterior registrado y falló después dentro de las últimas seis horas, Glossia puede crear una continuación en el lanzamiento actual. Usar el tiempo de cola también cubre trabajos que esperan capacidad y solo inician tras el despliegue. Un digest de imagen diferente por sí solo no desencadena reintentos de fallos ordinarios tras despliegues no relacionados. Los archivos completos y el pull request de traducción abierto se mantienen; solo el trabajo inconcluso se traduce nuevamente. Las continuaciones de lanzamiento en cola esperan mientras un despliegue está en progreso, por un máximo de 15 minutos. Fallos de la API de Kubernetes o de permisiones detienen el lanzamiento con un error explícito en vez de ser malinterpretado como un despliegue en curso.

La recuperación intencionadamente es estrecha: la sesión debe haber terminado con un fallo de validación de elemento registrado, y cada elemento fallido en su último intento debe informar un fallo de estructura Markdown, contenido preservado o unidad Markdown. Los intentos interrumpidos o parcialmente cancelados no califican. Los errores del proveedor, crédito agotado, credenciales rechazadas, fallos de publicación, errores de lectura de fuente, fallos de comandos de validación externos y causas desconocidas no se reintentan por un despliegue. Las sesiones exitosas, activas, canceladas, sustituidas y sin versión también quedan solas. Una sesión más nueva siempre gana, incluso si el usuario la canceló.

Una sesión recibe como máximo una continuación en un lanzamiento de motor diferente, con como máximo tres continuaciones de lanzamiento en un linaje. Si el nuevo motor sigue fallando, no se reintenta nuevamente en esa misma imagen, incluso tras una reversión. El linaje mantiene sus digests del motor intentados previamente, y el iniciador los verifica nuevamente antes de crear un trabajo en cola. Los límites de recuperación del proveedor existentes se mantienen entre continuaciones de lanzamiento. Las etiquetas de imagen mutables y los despliegues sin una identidad de lanzamiento configurada no habilitan la recuperación automática del motor.

## Progreso persistente

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción por lotes: un commit cada 25 archivos, o cada 15 minutos, y un commit final cuando termina la ejecución. Cada push ejecuta las comprobaciones de solicitud de extracción del repositorio, por lo que el agrupamiento evita que una gran ejecución inicie una comprobación individual por archivo. Un proyecto tiene una sola solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa la abierta, y solo traduce lo que ha cambiado desde entonces. Una vez que esa solicitud se fusiona o cierra, la próxima ejecución inicia una nueva. Dentro de los archivos no finalizados, los segmentos validados localmente y los lotes de recuperación también se guardan en la base de datos durante siete días. Estos puntos de control sobreviven a la detención de un proceso de trabajo. Están delimitados a la cuenta, al proyecto, a la entrada del documento, a la credencial y modelo efectivos, al contexto, y al segmento o intento de reparación.

Una ejecución reanudada solo puede reutilizar un segmento cuando sus entradas aún coinciden. Siempre valida nuevamente el documento ensamblado final. Las respuestas del modelo rechazadas no son puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado porque el validador no puede identificar un único segmento responsable.

Los puntos de control expirados y los registros de ritmo del proveedor inactivos se eliminan por el trabajador programado de recuperación de sesión. Estos son registros operativos; los usuarios no necesitan añadirlos a su repositorio ni configurar en `L10N.md`.
