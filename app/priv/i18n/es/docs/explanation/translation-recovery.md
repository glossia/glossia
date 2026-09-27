%{
  title: "Recuperación de traducción",
  summary:
    "Cómo Glossia se recupera de las limitaciones del proveedor y las traducciones interrumpidas.",
  category: "explicación",
  section: "traducción",
  order: 8
}
---
Glossia valida el contenido traducido antes de publicarlo. La recuperación conserva
ese requisito: un reintento aún debe conservar la estructura de origen y los requeridos
marcadores de posición, y cada archivo ensamblado pasa sus comandos de validación configurados.

## Traducción de catálogos

Los catálogos Gettext se parsean en cadenas antes de la traducción. Las solicitudes llevan hasta
más ocho cadenas, con un objetivo de lotes de 8,000 bytes. Una cadena más grande
se mantiene íntegra. El modelo devuelve un array con el mismo número de cadenas en
el mismo orden. Glossia verifica las variables de interpolación y rechaza las traducciones vacías.

Los encabezados se construyen en código utilizando las reglas de pluralización del idioma objetivo. Mensaje de origen
identificadores, comentarios y estructura del catálogo provienen de la fuente analizada. Si un
lote devuelve contenido malformado, Glossia lo vuelve a intentar una vez, luego lo divide en
lotes más pequeños. Los lotes adyacentes exitosos no necesitan traducirse nuevamente.

## Limitación del proveedor

Trabajadores que utilizan la misma credencial y modelo comparten la admisión de solicitudes a través de la
base de datos, incluidos trabajadores en distintas réplicas de aplicación. Un límite de tasa
respuesta extiende su tiempo de espera compartido e incrementa el intervalo entre nuevas solicitudes.
El tráfico exitoso reduce gradualmente ese espaciado después de un minuto sin limitación.
Las solicitudes ya en ejecución se permiten finalizar.

Las pistas de reintento del proveedor son retrasos mínimos. Los fallos repetidos también aumentan el
backoff, hasta un retraso base de 30 segundos más jitter; una pista del proveedor más larga toma
precedencia, limitada a cinco minutos. El de Together, `x-ratelimit-reset` el encabezado es
reconocido junto a `retry-after`.

Después de ocho intentos de solicitud sin éxito, la ejecución del repositorio deja de iniciar nuevos
archivos. Una continuación retrasada hereda la rama de traducción y reanuda su
trabajo inacabado. El intento anterior permanece visible en el historial de sesiones, vinculado
a través de la continuación. Los retrasos aumentan desde un minuto hasta cinco minutos, con
como máximo seis continuaciones automáticas. Las sesiones activas más recientes tienen prioridad, y
las sesiones canceladas nunca se reactivan. Los fallos de validación por sí solos no programan
la recuperación del proveedor.

## Progreso duradero

Los archivos completados y sus archivos de bloqueo se publican en la rama de traducción como
antes. Dentro de los archivos sin completar, los segmentos validados localmente y los lotes de recuperación
también se guardan en la base de datos durante siete días. Estos puntos de control sobreviven a un trabajador
proceso de trabajo se detienen. Están limitados a la cuenta, el proyecto, la entrada del documento,
credencial efectiva y modelo, contexto y segmento o intento de reparación.

Una ejecución reanudada puede reutilizar un segmento solo cuando sus entradas siguen coincidiendo. Siempre
valida nuevamente el documento ensamblado final. Las respuestas del modelo rechazadas no
puntos de control. Un fallo de validación a nivel de documento inicia un intento de reparación separado
porque el validador no puede identificar un único segmento responsable.

Los puntos de control expirados y los registros de ritmo del proveedor inactivos son eliminados por el
trabajador programado de recuperación de sesión. Estos son registros operativos; los usuarios no
necesitan agregarlos a su repositorio o configurarlos en `L10N.md`.