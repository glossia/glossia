%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene el Markdown intacto y se recupera de la limitación de velocidad del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  section: "translation",
  order: 8
}
---

Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva ese requisito: un reintento debe preservar aún la estructura del origen y los marcadores de posición requeridos, y cada archivo ensamblado pasa sus comandos de validación configurados.

## ## Traducción de Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Solo parsea el origen para encontrar su prosa: párrafos, encabezados, elementos de lista, celdas de tabla, los atributos visibles para el usuario de componentes y HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), y el texto de un HTML `<summary>`. Cada traducción se escribe de nuevo en los bytes exactos que ocupaba su origen, por lo que el código, los destinos de enlace, componentes, alertas de GitHub, anclajes de encabezado explícitos como `{#install}`, marcadores de lista y líneas en blanco permanecen idénticos byte a byte.

Cada párrafo o encabezado se traduce como una oración completa. El formato en línea se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras enlazadas o enfatizadas, y `<gN/>` para contenido que no puede cambiar, como código en línea o un componente. El modelo puede mover las etiquetas para seguir el orden de palabras del idioma de destino, pero debe mantener cada etiqueta exactamente una vez. Cada solicitud también lleva el documento fuente circundante y las traducciones más recientes del mismo archivo, para referencia.

Una unidad que elimina o inventa una etiqueta se envía nuevamente por sí misma, con la razón, hasta por tres veces. Las unidades que regresaron válidas se mantienen. Después del empalme, Glossia parsea el resultado y compara su estructura con el origen. Una traducción que por sí sola se convertiría en un encabezado, lista o énfasis tiene su prosa escapada, lo que no requiere más llamadas al modelo.

## ## Traducción de catálogos

Los catálogos Gettext se parsean en cadenas antes de la traducción. Las solicitudes transportan hasta ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena más grande individual permanece intacta. El modelo devuelve un array con la misma cantidad de cadenas en el mismo orden. Glossia comprueba las variables de interpolación y rechaza las traducciones vacías.

Los encabezados se construyen en código utilizando las reglas de plural del idioma de destino. Los identificadores de mensaje fuente, comentarios y la estructura del catálogo provienen del origen parseado. Si un lote devuelve contenido malformado, Glossia lo reintentará una vez, luego lo dividirá en lotes más pequeños. Los lotes vecinos exitosos no necesitan ser traducidos nuevamente.

## ## Limitación por proveedor

Glossia coordina las solicitudes de traducción que usan la misma credencial y modelo. Una respuesta de limitación de tasa extiende su periodo de enfriamiento compartido y aumenta la separación entre solicitudes nuevas. El tráfico exitoso reduce gradualmente esa separación después de un minuto sin limitación. Las solicitudes ya en ejecución se permiten terminar.

Las indicaciones de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el tiempo de espera progresivo, hasta un retraso base de 30 segundos más jitter; una indicación del proveedor más larga tiene precedencia, limitada a cinco minutos. El encabezado `x-ratelimit-reset` de Together se reconoce junto con `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio deja de iniciar nuevos archivos. Una continuación con retraso hereda la rama de traducción y reanuda su trabajo inacabado. El intento anterior permanece visible en el historial de sesión, vinculado a través de la continuación. Los retrasos aumentan desde un minuto hasta cinco minutos, con hasta seis continuaciones automáticas. Las sesiones activas más recientes tienen precedencia, y las sesiones canceladas nunca se reviven. Los fallos de validación por sí solos no agendan la recuperación del proveedor.

## ## Recuperación después del lanzamiento del motor

Una sesión tiene dos versiones independientes: el commit del repositorio que se está traduciendo y la imagen del motor de traducción que lo ejecuta. En Kubernetes, cada trabajo fija el digest de imagen exacto del réplica web que lo agendó. Los trabajos sobreviven a los despliegues web y nunca cambian el código a mitad de una traducción. Un trabajo agendado justo antes de un despliegue puede terminar en el motor anterior incluso después de que se haya actualizado la aplicación web. Los detalles de la sesión muestran el digest del motor; las sesiones más antiguas sin esta procedencia muestran "No registrado."

Cada cinco minutos, Glossia comprueba si su Despliegue se ha desplegado completamente. Solo un trabajador de esa versión sana puede agendar la recuperación del motor. Si la sesión más reciente de un proyecto se puso en cola antes de que se completara ese despliegue, se ejecutó en un digest de motor registrado más antiguo y falló después dentro de las últimas seis horas, Glossia puede crear una continuación en la versión actual. El uso del tiempo de cola también cubre trabajos que esperan capacidad y solo arrancan después del despliegue. Un digest de imagen diferente por sí solo no desencadena reintentos de fallos comunes después de despliegues no relacionados. Los archivos completados y el pull request de traducción abierto se llevan al siguiente; solo el trabajo inacabado se traduce nuevamente. Las continuaciones de versión en cola esperan mientras un despliegue está en progreso, por un máximo de 15 minutos. Los fallos de la API de Kubernetes o de permisos detienen el lanzamiento con un error explícito en lugar de ser confundidos con un despliegue en curso.

La recuperación es deliberadamente restringida: la sesión debe haber terminado con un fallo de validación de elemento registrado, y cada elemento fallido en su último intento debe reportar una estructura de Markdown, contenido preservado, o un fallo de unidad de Markdown. Los intentos interrumpidos o parcialmente cancelados no califican. Los errores del proveedor, crédito agotado, credenciales rechazadas, fallos de publicación, errores de lectura del origen, fallos de comandos de validación externos y causas desconocidas no se reintentan por un despliegue. También se ignoran las sesiones exitosas, activas, canceladas, obsoletas y sin versión. Una sesión más reciente siempre gana, incluso si el usuario la canceló.

Una sesión obtiene a lo sumo una continuación en una versión diferente del motor, con a lo sumo tres continuaciones de versión en una línea de descendencia. Si el nuevo motor sigue fallando, no se reintenta en esa misma imagen, incluso después de un rollback. La línea de descendencia conserva los digests de motor intentados anteriormente, y el lanzador los comprueba nuevamente antes de crear un trabajo en cola. Los límites existentes de recuperación del proveedor se preservan a través de las continuaciones de versión. Las etiquetas de imagen mutables y los despliegues sin una identidad de versión configurada no habilitan la recuperación automática del motor.

## ## Progreso persistente

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción por lotes: un commit por cada 25 archivos, o cada 15 minutos, y un commit final cuando termina la ejecución. Cada empuje ejecuta las comprobaciones de solicitud de extracción del repositorio, por lo que el agrupamiento evita que una ejecución grande inicie una comprobación por archivo. Un proyecto tiene una única solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa la que está abierta, y solo traduce lo que ha cambiado desde entonces. Una vez que esa solicitud de extracción se fusiona o cierra, la siguiente ejecución inicia una nueva. Dentro de los archivos sin finalizar, los segmentos validados localmente y los lotes de recuperación también se guardan en la base de datos durante siete días. Estos puntos de control sobreviven a la detención de un proceso de trabajador. Se limitan a la cuenta, el proyecto, la entrada del documento, la credencial y el modelo efectivos, el contexto, y el intento de segmento o reparación.

Una ejecución retomada solo puede reutilizar un segmento cuando sus entradas siguen coincidiendo. Siempre valida nuevamente el documento ensamblado final. Las respuestas del modelo rechazadas no son puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado porque el validador puede no identificar un único segmento responsable.

Los puntos de control expirados y los registros de ritmo del proveedor inactivos son eliminados por el trabajador programado de recuperación de sesión. Estos son registros operativos; los usuarios no necesitan agregarlos a su repositorio ni configurarlos en `L10N.md`.
