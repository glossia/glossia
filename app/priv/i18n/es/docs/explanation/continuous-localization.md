%{
  title: "Localización continua",
  summary:
    "Haga que los cambios de idioma formen parte del ciclo de entrega versionado del producto, no de un ciclo separado de exportación e importación.",
  category: "explicación",
  section: "translation",
  order: 2
}
---

La entrega continua funciona porque los pequeños cambios se mueven a través de un pipeline repetible: control de versiones, revisión, validación y despliegue. La localización debe encajar en ese flujo en lugar de introducir un sistema de registro no relacionado.

## El bucle desconectado

En un flujo de trabajo desconectado, un cambio del producto dispara una exportación, se realiza el trabajo en otra herramienta y el contenido traducido regresa eventualmente. Entre esos pasos, la fuente de origen puede cambiar nuevamente. Los equipos deben conciliar versiones, decidir si las traducciones están obsoletas y coordinar otro lanzamiento.

El problema no es que un editor web sea inherentemente incorrecto. Es que un sistema de edición con autoridad independiente puede separar las decisiones de idioma del código y la revisión de contenido que describan.

## El bucle del repositorio

El flujo de trabajo del repositorio de Glossia mantiene los archivos de origen y la configuración de localización en Git. Un repositorio conectado proporciona el contenido y los idiomas objetivo. Los cambios de traducción regresan como cambios de repositorio revisibles, por lo que los equipos pueden aplicar sus convenciones existentes de pull request y publicación.

Un ciclo típico es: 1. Un equipo cambia el contenido de origen con el producto. 2. Glossia identifica el contenido que necesita traducción o refinamiento. 3. La orientación del idioma y la terminología proporcionan contexto para la transformación. 4. La validación comprueba el resultado y los fallos permanecen accionables. 5. Los revisores inspeccionan los cambios antes de que el flujo de publicación los entregue.

1. Un equipo cambia el contenido de origen con el producto.
2. Glossia identifica el contenido que necesita traducción o refinamiento.
3. La orientación del idioma y la terminología proporcionan contexto para la transformación.
4. La validación comprueba el resultado y los fallos permanecen accionables.
5. Los revisores inspeccionan los cambios antes de que el flujo de publicación los entregue.

[Refinamiento progresivo](./progressive-refinement) explica cómo hashing y validación encajan en este ciclo. [Recuperación de traducción](./translation-recovery) explica qué sucede cuando la generación o validación falla.

## Continua no significa sin revisar

Un cambio continuamente entregable no es necesariamente un cambio aprobado automáticamente. El lenguaje legal, las promesas del producto y el material culturalmente sensible pueden necesitar revisión especializada. Mantener esa revisión en el flujo de entrega permite a un equipo elegir la puerta adecuada sin mantener una autoridad de publicación separada.

La localización continua no significa traducir todo el repositorio en cada commit. El contenido sin cambios no debe consumir los mismos recursos repetidamente.

## El límite práctico

Glossia proporciona contexto de idioma y mecanismos de localización. Las comprobaciones y el proceso de despliegue del repositorio aún definen cuándo un cambio es seguro para publicar. Glossia no es un sustituto de las pruebas de la aplicación ni la responsabilidad del editor por la precisión.

Otras plataformas también ofrecen integraciones de Git y automatización CI. La distinción es el centro de gravedad previsto: Glossia está construido en torno a la propiedad del contenido y la revisión en el repositorio, no un requisito para mover la autoridad editorial continua a un espacio de trabajo de traducción alojado.
