%{
  title: "Localización continua",
  summary:
    "Haz que los cambios de idioma formen parte del ciclo de entrega versionado del producto, no de un ciclo separado de exportación e importación.",
  category: "explicación",
  section: "translation",
  order: 2
}
---

La entrega continua funciona porque los pequeños cambios pasan por una tubería repetible: control de versiones, revisión, validación y despliegue. La localización debe encajar en esa tubería en lugar de introducir un sistema de registro no relacionado.

## El bucle desconectado

En un flujo de trabajo desconectado, un cambio del producto desencadena una exportación, el trabajo se realiza en otra herramienta y el contenido traducido finalmente regresa. Entre estos pasos, el origen puede cambiar nuevamente. Los equipos deben ajustar las versiones, decidir si las traducciones están obsoletas y coordinar otro lanzamiento.

El problema no es que un editor web sea inherentemente incorrecto. Es que un sistema de edición con autoridad independiente puede separar las decisiones lingüísticas del código y la revisión de contenido que describe.

## El bucle del repositorio

El flujo de trabajo del repositorio de Glossia mantiene los archivos de origen y la configuración de localización en Git. Un repositorio conectado proporciona el contenido y los idiomas objetivo. Los cambios de traducción regresan como cambios de repositorio revisables, por lo que los equipos pueden aplicar sus convenciones existentes de solicitud de extracción y publicación.

Un bucle típico es:

1. Un equipo modifica el contenido de origen en el producto.
2. Glossia identifica el contenido que necesita traducción o refinamiento.
3. La orientación del idioma y la terminología proporcionan contexto para la transformación.
4. La validación comprueba el resultado y los fallos permanecen solucionables.
5. Los revisores inspeccionan los cambios antes de que la tubería de publicación los entregue.

[Refinamiento progresivo](./progressive-refinement) explica cómo el hash y la validación encajan en este bucle. [Recuperación de traducción](./translation-recovery) explica qué sucede cuando la generación o la validación falla.

## La entrega continua no significa falta de revisión

Un cambio continuamente entregable no es necesariamente un cambio aprobado automáticamente. El lenguaje legal, las promesas de producto y el material culturalmente sensible pueden necesitar revisión especializada. Mantener esa revisión en el bucle de entrega permite a un equipo elegir el paso adecuado sin mantener una autoridad de publicación separada.

La localización continua tampoco significa traducir todo el repositorio en cada commit. El contenido sin cambios no debe consumir los mismos recursos repetidamente.

## El límite práctico

Glossia proporciona contexto lingüístico y mecánica de localización. Las verificaciones y el proceso de despliegue de su repositorio siguen definiendo cuándo un cambio es seguro para publicar. Glossia no es un sustituto de las pruebas de aplicación ni la responsabilidad del editor por la precisión.

Otras plataformas también ofrecen integraciones de Git y automatización de CI. La distinción es el centro de gravedad previsto: Glossia está construido alrededor de la propiedad del contenido y la revisión en el repositorio, no siendo un requisito trasladar la autoridad editorial continua a un espacio de trabajo de traducción alojado.
