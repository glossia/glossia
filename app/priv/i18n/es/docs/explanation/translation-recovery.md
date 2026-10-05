%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia se recupera de la limitación del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  section: "translation",
  order: 8
}
---
Glossia valida el contenido traducido antes de publicarlo. La recuperación preserva
ese requisito: un nuevo intento debe seguir conservando la estructura fuente y requeridos
marcadores de posición, y cada archivo ensamblado cumple sus comandos de validación configurados.

## Traducción de catálogo

Los catálogos de Gettext se convierten en cadenas antes de su traducción. Las solicitudes transportan a
lo sumo ocho cadenas, con un objetivo de lote de 8.000 bytes. Una cadena más grande
permanece intacta. El modelo devuelve un array con la misma cantidad de cadenas en el
mismo orden. Glossia verifica las variables de interpolación y rechaza las traducciones vacías.

Los encabezados se construyen en el código utilizando las reglas de plural del idioma objetivo. Mensaje fuente
identificadores, comentarios y la estructura del catálogo provienen del origen analizado. Si un
lote devuelve contenido malformado, Glossia lo reintentará una vez, luego lo divide en
lotes más pequeños. Los lotes adyacentes exitosos no necesitan ser traducidos de nuevo.

## Limitación de tasa del proveedor

Glossia coordina las solicitudes de traducción que utilizan la misma credencial y modelo. Un límite de tasa
la respuesta extiende su tiempo de espera compartido e incrementa el intervalo entre las nuevas solicitudes.
El tráfico exitoso reduce gradualmente ese intervalo después de un minuto sin limitación de tasa.
Las solicitudes en ejecución están permitidas para finalizar.

Las indicaciones de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el
retraso, de hasta un retraso base de 30 segundos más jitter; una indicación más larga del proveedor tiene
prioridad, limitada a cinco minutos. De Together `x-ratelimit-reset` el encabezado es
reconocido junto a `retry-after`.

Después de ocho intentos de petición sin éxito, la ejecución del repositorio deja de iniciar nuevas
archivos. Una continuación demorada hereda la rama de traducción y reanuda su
trabajo pendiente. El intento anterior permanece visible en el historial de sesion de traduccion, vinculado
a través de la continuación. Los retrasos aumentan desde un minuto hasta cinco minutos, con
un máximo de seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y
las sesiones canceladas nunca se reactivan. Los fallos de validación por sí solos no programan
recuperación del proveedor.

## Progreso persistente

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción como
Antes. Dentro de los archivos inconclusos, los segmentos validados localmente y los lotes de recuperación
también se guardan en la base de datos durante siete días. Estos puntos de control sobreviven ante un trabajador
proceso que se detiene. Se aplican a la cuenta, el proyecto, la entrada del documento,
credencial efectiva y modelo, el contexto y el segmento o intento de reparación.

Una ejecución reanudada puede reutilizar un segmento solo cuando sus entradas aún coinciden. Siempre
valida nuevamente el documento final ensamblado. Las respuestas del modelo rechazadas no
puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado
porque el validador puede no identificar un solo segmento responsable.

Los puntos de control caducados y los registros de ritmo del proveedor inactivos se eliminan por el
trabajador de recuperación de sesiones programado. Estos son registros operativos; los usuarios no
necesitan añadirlas a su repositorio o configurarlos en `L10N.md`.