%{
  title: "Localización continua",
  summary:
    "Haga que los cambios de idioma formen parte del bucle de entrega versionado del producto, no de un ciclo separado de exportación e importación.",
  category: "explicación",
  section: "translation",
  order: 2
}
---

La entrega continua funciona porque los cambios pequeños se mueven a través de un pipeline repetible: control de versiones, revisión, validación y despliegue. La localización debe encajar en ese pipeline en lugar de introducir un sistema de registro no relacionado.

## El bucle desconectado

En un flujo de trabajo desconectado, un cambio del producto desencadena una exportación, el trabajo se realiza en otra herramienta y el contenido traducido regresa eventualmente. Entre esos pasos, el origen puede cambiar nuevamente. Los equipos deben reconciliar versiones, decidir si las traducciones están obsoletas y coordinar otro lanzamiento.

El problema no es que un editor web sea inherentemente incorrecto. Es que un sistema de edición independientemente autorizado puede separar las decisiones de idioma del código y la revisión de contenido que describen.

## El bucle de repositorio

El flujo de trabajo de repositorio de Glossia mantiene los archivos fuente y la configuración de localización en Git. Un repositorio conectado suministra el contenido y los idiomas objetivo. Los cambios de traducción regresan como cambios revisables del repositorio, por lo que los equipos pueden aplicar sus convenciones existentes de solicitud de extracción y publicación.

Un bucle típico es:

1. Un equipo cambia el contenido fuente con el producto.
2. Glossia identifica el contenido que necesita traducción o refinamiento.
3. La orientación lingüística y la terminología proveen contexto para la transformación.
4. La validación comprueba el resultado y los fallos permanecen accionables.
5. Los revisores revisan los cambios antes de que la tubería de publicación los entregue.

[Refinamiento progresivo](./progressive-refinement) explica cómo el hashing y la validación encajan en este bucle. [Recuperación de traducción](./translation-recovery) explica lo que sucede cuando la generación o la validación fallan.

## La continuidad no significa sin revisión

Un cambio continuamente entregable no es necesariamente un cambio aprobado automáticamente. El lenguaje legal, las promesas del producto y los materiales culturalmente sensibles pueden necesitar revisión especializada. Mantener esa revisión en el bucle de entrega permite a un equipo elegir la compuerta adecuada sin mantener una autoridad de publicación separada.

La localización continua no significa traducir todo el repositorio en cada commit. El contenido sin cambios no debería consumir los mismos recursos repetidamente.

## El límite práctico

Glossia suministra contexto lingüístico y mecánicas de localización. Las comprobaciones y el proceso de despliegue de tu repositorio aún definen cuándo es seguro publicar un cambio. Glossia no es un sustituto de las pruebas de aplicación ni la responsabilidad de un editor por la precisión.

Otras plataformas también ofrecen integraciones de Git y automatización de CI. La distinción es el centro de gravedad previsto: Glossia está construido en torno a la propiedad del contenido y la revisión en el repositorio, no un requisito para mover la autoridad editorial continua a un espacio de trabajo de traducción alojado.
