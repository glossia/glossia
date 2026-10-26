%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "referencia",
  section: "translation",
  order: 2
}
---

La configuración del proyecto prepara un repositorio conectado para Glossia. Después de que un usuario selecciona un repositorio en el flujo **Nuevo proyecto**, elige una de las dos opciones de configuración.

## Modos de configuración

| Modo | Qué hace Glossia | Cuándo elegirlo |
|---|---|---|
| **Configuración automática** | Inspecciona el repositorio y abre una solicitud de extracción con la configuración `L10N.md` generada para los idiomas objetivo seleccionados. | El repositorio aún no tiene configuración de localización. |
| **Configuración manual** | Crea el proyecto inmediatamente. No inspecciona, modifica ni abre una solicitud de extracción del repositorio. | El repositorio ya tiene un archivo `L10N.md` o un mantenedor lo escribirá. |

Los estados, la información de progreso y la solicitud de extracción descrita a continuación se aplican solo a la configuración automática.

## Configuración manual

Un proyecto configurado manualmente no tiene estado de configuración. Es utilizable tan pronto como se crea y nunca se descarta por una configuración fallida.

Glossia inicia una sesión de traducción en el siguiente push a la rama principal del repositorio. La sesión traduce a cada objetivo declarado en los archivos [`L10N.md`](/docs/reference/l10n-md) del repositorio, porque no se seleccionan idiomas objetivo en el flujo **Nuevo proyecto**.

Hasta la primera sesión de traducción, el resumen del proyecto muestra un aviso explicando que Glossia está esperando un push que incluya un archivo `L10N.md`.

## Prerrequisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Para la configuración automática, debe seleccionarse al menos un idioma objetivo.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Seguir el progreso o salir de la página y volver más tarde. |
| **En ejecución** | Glossia está inspeccionando y actualizando el repositorio. | Seguir la actividad en vivo. |
| **Completado** | La línea base de localización se preparó y publicó para su revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras la configuración esté **Pendiente** o **En ejecución**. Si la configuración no puede finalizar o publicar un cambio utilizable, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio luego se vuelve disponible en el flujo **Nuevo proyecto** para intentar la configuración nuevamente.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Un distintivo de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación, inspección, cambio de archivo, verificación y finalización del repositorio.
- Un mensaje de fallo claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama principal del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` contexto y los cambios prácticos mínimos necesarios para cargar contenido localizado.

La configuración no publica catálogos objetivo de solo cabecera. Cuando un marco de localización requiere catálogos objetivo antes de la traducción, los catálogos contienen las entradas de mensajes de origen extraídas con valores de traducción vacíos. Cuando los catálogos objetivo aún no son requeridos, la configuración los deja para la primera sesión de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y la fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras esta solicitud de extracción está abierta. El aviso se elimina después de fusionar la solicitud de extracción. Si la solicitud de extracción se cierra sin fusionarse, el resumen explica que debe reabrirse antes de que la configuración pueda considerarse completada.
