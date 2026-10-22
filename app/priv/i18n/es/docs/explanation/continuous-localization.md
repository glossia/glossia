%{
  title: "Localización continua",
  summary:
    "Haz que los cambios de idioma formen parte del bucle de entrega versionado del producto, no de un ciclo separado de exportación e importación.",
  category: "explicación",
  section: "translation",
  order: 2
}
---

La entrega continua funciona porque los cambios pequeños se mueven a través de una tubería repetible: control de versiones, revisión, validación y despliegue. La localización debe encajar en esa tubería en lugar de introducir un sistema de registro no relacionado.

## El bucle desconectado

En un flujo de trabajo desconectado, un cambio de producto desencadena una exportación, el trabajo tiene lugar en otra herramienta y el contenido traducido eventualmente regresa. Entre esos pasos, el contenido fuente puede cambiar nuevamente. Los equipos tienen que reconciliar versiones, decidir si las traducciones están obsoletas y coordinar otro lanzamiento.

El problema no es que un editor web sea inherentemente incorrecto. Es que un sistema de edición con autoridad independiente puede separar las decisiones de idioma del código y la revisión de contenido que describen.

## El bucle del repositorio

El flujo de trabajo del repositorio de Glossia mantiene los archivos de fuente y la configuración de localización en Git. Un repositorio conectado suministra el contenido y los idiomas de destino. Los cambios de traducción regresan como cambios de repositorio revisables, para que los equipos puedan aplicar sus convenciones existentes de solicitud de extracción y publicación.

Un bucle típico es:

1. Un equipo cambia el contenido fuente con el producto.
2. Glossia identifica el contenido que necesita traducción o refinamiento.
3. La orientación del idioma y la terminología proporcionan contexto para la transformación.
4. La validación comprueba el resultado y los fallos permanecen accionables.
5. Los revisores inspeccionan los cambios antes de que la tubería de publicación los entregue.

[Refinamiento progresivo](./progressive-refinement) explica cómo la generación de hash y la validación encajan en este bucle. [Recuperación de traducción](./translation-recovery) explica qué sucede cuando la generación o la validación falla.

## Continuo no significa sin revisar

Un cambio continuamente entregable no es necesariamente un cambio aprobado automáticamente. El lenguaje legal, las promesas del producto y el material culturalmente sensible pueden necesitar una revisión de especialistas. Mantener esa revisión en el bucle de entrega permite que un equipo seleccione la pasarela adecuada sin mantener una autoridad de publicación separada.

Del mismo modo, la localización continua no significa traducir todo el repositorio en cada commit. El contenido inalterable no debe consumir los mismos recursos repetidamente.

## El límite práctico

Glossia proporciona contexto de idioma y mecánicas de localización. Las comprobaciones y el proceso de despliegue de tu repositorio aún definen cuándo un cambio es seguro para publicar. Glossia no es un sustituto de las pruebas de la aplicación ni la responsabilidad de un editor por la precisión.

Otras plataformas también ofrecen integración de Git e automatización de CI. La distinción es el centro de gravedad previsto: Glossia está construido en torno a la propiedad del contenido y la revisión en el repositorio, no en un requisito para mover la autoridad editorial continua a un espacio de trabajo de traducción alojado.
