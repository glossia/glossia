%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia mantiene el Markdown intacto y se recupera de la limitación del proveedor y de las traducciones interrumpidas.",
  category: "Explicación",
  section: "translation",
  order: 8
}
---
Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva
ese requisito: una repetición debe preservar aún la estructura del origen y los requeridos
marcadores de posición, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción de Markdown

Glossia nunca vuelve a renderizar un documento Markdown traducido. Analiza el origen
solo para encontrar su prosa: párrafos, encabezados, artículos de lista, celdas de tabla, el
atributos visuales de los componentes y de HTML (`title`, `details`, `alt`,
`label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), y
el texto de un HTML `<summary>`. Cada traducción se escribe de nuevo en los bytes
exactos que ocupaba su fuente, por lo que código, destinos de enlace, componentes, GitHub
advertencias, marcadores explícitos de encabezado tales como `{#install}`, marcadores de lista y líneas
en blanco se mantengan idéntico byte a byte.

Cada párrafo o encabezado se traduce como una frase completa. El formato en línea
se convierte en etiquetas numeradas: `<gN>...</gN>` alrededor de palabras enlazadas o enfatizadas, y
`<gN/>` para el contenido que no debe cambiar, como código en línea o un componente.
El modelo puede mover etiquetas para seguir el orden de palabras del idioma objetivo, pero debe
mantener cada etiqueta exactamente una vez. Cada solicitud también lleva el documento fuente
circundante, y las traducciones más recientes del mismo archivo, para referencia.

Una unidad que elimina o inventa una etiqueta se envía de nuevo por sí misma, con la razón,
hasta tres veces. Las unidades que volvieron válidas se conservan. Después de empalme, Glossia
analiza el resultado y compara su estructura con la fuente. Una traducción que
se convertiría en un encabezado, lista o énfasis por sí misma necesita su prosa escapada,
que no requiere ninguna llamada de modelo adicional.

## Traducción de catálogo

Los catálogos de Gettext se analizan en cadenas antes de la traducción. Las solicitudes llevan al
más ocho cadenas, con un objetivo de agrupación de 8,000 bytes. Una cadena individual más grande
permanece intacta. El modelo devuelve un array con el mismo número de cadenas en el
mismo orden. Glossia comprueba las variables de interpolación y rechaza traducciones vacías.

Los encabezados se construyen en código utilizando las reglas de plural del idioma objetivo. Los mensajes de origen
identificadores, comentarios y estructura de catálogo provienen del origen analizado. Si un
lote devuelve contenido defectuoso, Glossia lo reintentará una vez, luego lo divide en
lotes más pequeños. Los lotes vecinos exitosos no necesitan ser traducidos nuevamente.

## Limitación de proveedor

Glossia coordina las solicitudes de traducción que utilizan la misma credencial y modelo. Una respuesta de limitación de velocidad
extiende su tiempo de espera compartido y aumenta el espaciado entre nuevas solicitudes.
El tráfico exitoso reduce gradualmente ese espaciado después de un minuto sin limitación.
Las solicitudes ya en ejecución se permiten terminar.

Las pistas de reintento del proveedor son retrasos mínimos. Los fallos repetidos también incrementan el
retraso, hasta un retraso base de 30 segundos más jitter; una pista de proveedor más larga tiene
precedencia, limitada a cinco minutos. El encabezado `x-ratelimit-reset` de Together es
reconocido junto a `retry-after`.

Después de ocho intentos de solicitud no exitosos, la ejecución del repositorio deja de iniciar nuevos
archivos. Una continuidad con retraso hereda la rama de traducción y reanuda su
trabajo incompleto. El intento anterior permanece visible en el historial de sesiones, vinculado
a través de la continuidad. Los retrasos aumentan de un minuto a cinco minutos, con
al más seis continuaciones automáticas. Las sesiones activas más nuevas toman precedencia, y
las sesiones canceladas nunca se reactivan. Los fallos de validación por sí solos no programan
la recuperación del proveedor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción en
lotes: un commit por cada 25 archivos, o cada 15 minutos, y un commit final
cuando termina la ejecución. Cada push ejecuta las verificaciones de solicitud de extracción del repositorio, por lo que
el procesamiento por lotes evita que una gran ejecución inicie una verificación por archivo. Un proyecto tiene
una única solicitud de extracción de traducción: un nuevo commit en la rama predeterminada continúa
la abierta, y solo traduce lo que ha cambiado desde. Una vez que esa solicitud de extracción
se fusiona o se cierra, la próxima ejecución inicia una nueva. Dentro de los archivos inacabados, los segmentos validados localmente y los lotes de recuperación
se guardan también en la base de datos durante siete días. Estos puntos de control sobreviven a un trabajador
proceso deteniéndose. Estas se limitan a la cuenta, proyecto, entrada del documento,
credencial y modelo efectivos, contexto y segmento o intento de reparación.

Una ejecución reanudada solo puede reutilizar un segmento cuando sus entradas aún coinciden. Siempre
vuelve a validar el documento ensamblado final. Las respuestas del modelo rechazadas no
puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado
porque el validador puede no identificar un solo segmento responsable.

Expirados los puntos de control y registros de ritmo del proveedor inactivos son eliminados por el
programado de recuperación de sesión. Estos son registros operativos; los usuarios no
necesitan añadirlas a su repositorio o configurarlas en `L10N.md`.