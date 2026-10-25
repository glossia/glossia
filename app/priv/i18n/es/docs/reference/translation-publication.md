%{
  title: "Publicación de traducción",
  summary:
    "Reutilización de solicitudes pull, agrupación y el límite de push a nivel de proyecto.",
  category: "Referencia",
  section: "translation",
  order: 10
}
---

Glossia mantiene una solicitud de extracción de traducción abierta por proyecto. Los nuevos commits de la rama predeterminada continúan su rama en lugar de abrir una solicitud de extracción para cada commit de origen. Se crea una nueva solicitud de extracción después de que se haya fusionado o cerrado la anterior.

La publicación y el reemplazo de sesión comparten un bloqueo de proyecto respaldado por base de datos, incluso cuando se ejecutan en diferentes réplicas de la aplicación o en ejecutores desconectados. Si un ejecutor creó una solicitud de extracción pero no pudo guardar sus metadatos, la siguiente publicación recupera la solicitud de extracción de Glossia abierta de GitHub antes de crear otra. Una solicitud de extracción abierta no se abandona cuando su rama entra en conflicto con el origen o el historial del origen se reescribe: la sesión falla y mantiene la publicación existente para su resolución.

## Límite de empujes

El límite se mantiene fijo en **4 empujes por hora por proyecto**, compartido entre sesiones y réplicas. No es actualmente configurable.

Los empujes se distribuyen equitativamente, sin contar en bloques de horas fijas del reloj. Las actualizaciones de rama se separan al menos 15 minutos. El próximo intervalo comienza cuando termina un intento de publicación, por lo que un lote lento no puede ser seguido inmediatamente por uno rápido. Las fusiones de la rama de origen, los lotes intermedios, los reintentos y los envíos finales comparten el mismo presupuesto. Los intentos fallidos ambiguos consumen también un cupo, porque GitHub podría haber avanzado la rama antes de fallar la conexión. El presupuesto se almacena en PostgreSQL y no se reinicia con una nueva sesión ni con el reinicio del proceso.

## Agrupamiento

Una ejecución recopila cambios de archivos validados y solicita publicación después de 25 archivos o 15 minutos. Estos umbrales no eluden el límite de empujes. Durante un periodo de enfriamiento, los archivos adicionales terminados se unen al lote pendiente; los cambios repetidos a la misma ruta mantienen el contenido más reciente.

Al finalizar la ejecución, el envío final espera el mismo presupuesto. La sesión permanece activa y envía latidos mientras espera. Revisa la cancelación y la admisión periódicamente sin mantener una transacción de base de datos abierta mientras descansa.
