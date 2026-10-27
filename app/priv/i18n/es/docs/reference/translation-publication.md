%{
  title: "Publicación de traducciones",
  summary:
    "Reutilización de solicitudes de extracción, procesamiento por lotes y el límite de subida a nivel de proyecto.",
  category: "referencia",
  section: "translation",
  order: 10
}
---

Glossia mantiene un solo pedido de extracción de traducción abierto por proyecto. Los nuevos commits de la rama por defecto continúan su rama en lugar de abrir un pedido de extracción por cada commit de origen. Se crea un nuevo pedido de extracción después de que el anterior se haya fusionado o cerrado. Una publicación cerrada recibe un nombre de rama fresco, incluso al volver a intentar el mismo commit de origen; sus salidas rechazadas no se reutilizan como trabajo completado.

La sincronización de origen ocurre en una verificación local desechable antes de la evaluación, preservando las traducciones completadas y los archivos de bloqueo de la rama abierta. Una ejecución que no encuentra cambios de salida ni de archivos de bloqueo no avanza la rama remota simplemente para estar al día con la rama por defecto, y no gasta una asignación de publicación. Cuando un lote está listo, la sincronización de origen y los cambios validados se publican juntos en una única actualización de rama no forzada. El commit conserva tanto la publicación anterior como el commit de origen evaluado como antecesores.

La publicación y el reemplazo de sesión comparten un bloqueo de proyecto respaldado por base de datos, incluso cuando se ejecutan en réplicas de aplicación diferentes o ejecutores independientes. Si un ejecutor creó un pedido de extracción pero no pudo guardar sus metadatos, la próxima publicación recupera el pedido de extracción de Glossia abierto de GitHub antes de crear otro. Un pedido de extracción abierto no se abandona cuando su rama entra en conflicto con el origen o el historial del origen se reescribe: la sesión falla y conserva la publicación existente para resolución.

## Límite de push

El límite está fijo en **4 envíos por hora por proyecto**, compartido entre sesiones y réplicas. No es actualmente configurable.

Los envíos se reparten uniformemente, no se cuentan en intervalos fijos de horas reloj. Las actualizaciones de rama están al menos a 15 minutos de distancia entre sí. El siguiente intervalo comienza cuando finaliza un intento de publicación, por lo que un lote lento no puede ser seguido inmediatamente por uno rápido. Los lotes intermedios, los reintentos y los desflujos finales comparten el mismo presupuesto. Los intentos fallidos ambiguos consumen también una asignación, porque GitHub puede haber avanzado la rama antes de que fallara la conexión. El presupuesto se almacena en PostgreSQL y no se resetea por el inicio de una nueva sesión o la reiniciación del proceso.

Antes de publicar, Glossia vuelve a leer el extremo remoto y fusiona el origen de la sesión localmente de nuevo. Esto preserva lotes anteriores y detecta conflictos sin mover la rama. Si una actualización anterior tuvo éxito pero se perdió su respuesta, los cambios ya presentes no se vuelven a commit; los metadatos de publicación y el pedido de extracción se recuperan sin otra actualización de rama. Si el ref se creó pero el ejecutor se detuvo antes de crear su pedido de extracción, una evaluación sin cambios aún crea el pedido de extracción faltante, sin gastar una asignación de actualización de rama.

Un avance remoto inesperado se acepta solo cuando sus diferencias con respecto al árbol de sincronización esperado son partes del lote pendiente que ya están presentes. Otras ediciones realizadas durante la evaluación fallan en publicación en lugar de ser sobrescritas o publicar traducciones validadas contra entradas desactualizadas. El pedido de extracción existente se conserva para resolución.

## Lotes

Una ejecución recopila cambios de archivos validados y solicita publicación después de 25 archivos o 15 minutos. Estos umbrales no eluden el límite de push. Durante un tiempo de espera, archivos adicionales terminados se unen al lote Pendiente; los cambios repetidos a la misma ruta conservan el contenido más reciente.

Al final de la ejecución, el desflujo final espera por el mismo presupuesto. La sesión permanece activa y envía latidos mientras espera. Vuelve a comprobar la cancelación y la admisión periódicamente sin mantener una transacción de base de datos abierta mientras duerme.
