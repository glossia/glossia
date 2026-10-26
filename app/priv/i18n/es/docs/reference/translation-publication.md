%{
  title: "Publicación de traducción",
  summary:
    "Reutilización de pull requests, agrupamiento y el límite de envíos a nivel del proyecto.",
  category: "Referencia",
  section: "translation",
  order: 10
}
---

Glossia mantiene una solicitud de extracción de traducción abierta por proyecto. Los nuevos compromisos de la rama por defecto continúan su rama en lugar de abrir una solicitud de extracción para cada compromiso de origen. Una nueva solicitud de extracción se crea después de que la anterior se fusiona o cierra.

La publicación y el reemplazo de sesión comparten un bloqueo de proyecto respaldado por base de datos, incluso cuando se ejecutan en réplicas de aplicación diferentes o ejecutores desconectados. Si un ejecutor creó una solicitud de extracción pero no pudo guardar sus metadatos, la próxima publicación recupera la solicitud de extracción de traducción abierta de Glossia de GitHub antes de crear otra. Una solicitud de extracción abierta no se abandona cuando su rama tiene conflictos con el origen o se reescribe el historial del origen: la sesión falla y retiene la publicación existente para su resolución.

## Límite de empuje

El límite está fijado en **4 empujes por hora por proyecto**, compartido entre sesiones y réplicas. Actualmente no es configurable.

Los empujes están espaciados uniformemente, no se cuentan en contenedores de hora del reloj. Las actualizaciones de rama están separadas por al menos 15 minutos. El próximo intervalo comienza cuando un intento de publicación termina, por lo que un lote lento no puede seguirse inmediatamente por uno rápido. Las fusiones de rama de origen, los lotes intermedios, los reintentos y los vaciados finales comparten el mismo presupuesto. Los intentos fallidos ambiguos también consumen un hueco, porque GitHub pudo haber avanzado la rama antes de que fallara la conexión. El presupuesto se almacena en PostgreSQL y no se restablece con una nueva sesión o reinicio de proceso.

## Programación por lotes

Una ejecución recopila cambios de archivo validados y solicita publicación después de 25 archivos o 15 minutos. Estos umbrales no eluden el límite de empuje. Durante un periodo de enfriamiento, los archivos completados adicionales se unen al lote pendiente; los cambios repetidos a la misma ruta mantienen el contenido más reciente.

Al final de la ejecución, el vaciado final espera el mismo presupuesto. La sesión permanece activa y envía latidos mientras espera. Revisa periódicamente la cancelación y la admisión sin mantener una transacción de base de datos abierta mientras está en reposo.
