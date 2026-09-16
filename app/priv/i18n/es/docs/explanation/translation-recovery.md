%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia se recupera de las limitaciones del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  order: 8
}
---
Glossia valida el contenido traducido antes de publicarlo. La recuperación conserva
ese requisito: un nuevo intento aún debe preservar la estructura de la fuente y los requeridos
marcadores de posición, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción del catálogo

Los catálogos de Gettext se analizan en cadenas antes de la traducción. Las solicitudes transportan al
como máximo ocho cadenas, con un objetivo de agrupación de 8.000 bytes. Una cadena más grande
se mantiene intacta. El modelo devuelve un array con el mismo número de cadenas en el
misma orden. Glossia comprueba las variables de interpolación y rechaza las traducciones vacías.

Los encabezados se construyen en código utilizando las reglas de plural del idioma destino. Mensaje de origen
identificadores, comentarios y la estructura del catálogo provienen del origen analizado. Si un
lote devuelve contenido malformado, Glossia lo reintenta una vez, luego lo divide en
lotes más pequeños. Los lotes adyacentes exitosos no necesitan ser traducidos nuevamente.

## Limitación del proveedor

Los trabajadores que utilizan la misma credencial y modelo comparten la admisión de solicitudes a través del
base de datos, incluidos los trabajadores en diferentes réplicas de la aplicación. Una limitación de
respuesta extiende su tiempo de espera compartido y aumenta el espaciado entre las nuevas solicitudes.
El tráfico exitoso reduce gradualmente ese espaciado después de un minuto sin limitación.
Las solicitudes que ya se están ejecutando pueden finalizar.

Las sugerencias de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el
backoff, hasta un retraso base de 30 segundos más jitter; una sugerencia más larga del proveedor tiene
precedencia, limitada a cinco minutos. De Together `x-ratelimit-reset` encabezado es
reconocido junto a `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio deja de iniciar nuevas
archivos. Una continuación diferida hereda la rama de traduccion y reanuda su
trabajo inacabado. El intento anterior permanece visible en el historial de sesiones, vinculado
a través de la continuación. Los retrasos aumentan de un minuto a cinco minutos, con
un máximo de seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y
las sesiones canceladas nunca se reviven. Los fallos de validación por sí solos no programan
la recuperación del proveedor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción como
antes. Dentro de los archivos sin finalizar, los segmentos validados localmente y los lotes de recuperación
también se guardan en la base de datos durante siete días. Estos puntos de control superviven a un trabajador
proceso deteniéndose. Se limitan a la cuenta, el proyecto, la entrada del documento,
la credencial efectiva y el modelo, el contexto y el segmento o intento de reparación.

Una ejecución reanudada solo puede reutilizar un segmento cuando las entradas todavía coinciden. Siempre
valida nuevamente el documento final ensamblado. Las respuestas del modelo rechazadas
no son puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación independiente
porque el validador puede no identificar un segmento responsable único.

Los puntos de control expirados y los registros de ritmo de proveedor inactivos se eliminan por el
trabajador programado de recuperación de sesión. Estos son registros operativos; los usuarios no
necesitan añadirlos a su repositorio o configurarlos en `L10N.md`.