%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "referencia",
  section: "translation",
  order: 2
}
---

La configuración del proyecto prepara un repositorio conectado para Glossia. Después de que un usuario selecciona un repositorio en el flujo **Nuevo proyecto**, elige uno de dos modos de configuración.

## Modos de configuración

| Modo | Lo que hace Glossia | Cuándo elegirlo |
|---|---|---|
| **Configuración automatizada** | Inspecciona el repositorio y abre una solicitud de extracción de cambios con la `L10N.md` configuración generada para los idiomas objetivo seleccionados. | El repositorio aún no tiene configuración de localización. |
| **Configuración manual** | Crea el proyecto inmediatamente. No revisa el repositorio, lo modifica ni abre una solicitud de extracción de cambios. | El repositorio ya tiene un archivo `L10N.md` o un administrador lo escribirá. |

Los estados, la información de progreso y la solicitud de extracción de cambios descritos a continuación solo se aplican a la configuración automatizada.

## Configuración manual

Un proyecto configurado manualmente no tiene estado de configuración. Es funcional desde la creación y nunca se descarta por una configuración fallida.

Glossia inicia una ejecución de traducción tras el próximo push a la rama predeterminada del repositorio. Esta ejecución traduce a cada objetivo declarado en los archivos [`L10N.md`](/docs/reference/l10n-md) del repositorio, ya que no se seleccionan idiomas objetivo en el flujo **Nuevo proyecto**.

Hasta la primera ejecución de traducción, el resumen del proyecto muestra un aviso indicando que Glossia espera un push que incluya un archivo `L10N.md`.

## Requisitos previos

- La cuenta tiene al menos un modelo configurado.
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Para la configuración automatizada, se debe seleccionar al menos un idioma objetivo.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando comenzar. | Sigue el progreso o sal de la página y vuelve más tarde. |
| **En ejecución** | Glossia está revisando y actualizando el repositorio. | Observa la actividad en vivo. |
| **Completado** | La línea base de localización se preparó y publicó para su revisión. | Abre, revisa y fusiona la solicitud de extracción de cambios. |

Los proyectos son provisionales mientras la configuración esté **Pendiente** o **En ejecución**. Si la configuración no puede finalizar o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio entonces se vuelve disponible en el flujo **Nuevo proyecto** para que la configuración puedan intentarse de nuevo.

## Progreso visible

La tarjeta de configuración sigue estando disponible en el flujo del nuevo proyecto y en el resumen del proyecto. Incluye:

- Una insignia de estado y una barra de progreso.
- Una explicación breve del estado actual.
- Actividad reciente de preparación del repositorio, inspección, cambio de archivo, comprobación y finalización.
- Un mensaje de fallo claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción de cambios contra la rama predeterminada del repositorio. La solicitud de extracción de cambios contiene la línea base de localización generada, incluyendo el contexto `L10N.md` y los cambios prácticos más pequeños necesarios para cargar contenido localizado.

La configuración no publica catálogos objetivo solo de encabezado. Cuando un marco de localización requiere catálogos objetivo antes de la traducción, los catálogos contienen las entradas de mensajes fuente extraídas con valores de traducción vacíos. Cuando los catálogos objetivo aún no son necesarios, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción de cambios. Los mantenedores del repositorio la revisan y la fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras esta solicitud de extracción de cambios está abierta. El aviso se elimina después de que la solicitud de extracción de cambios se fusiona. Si la solicitud de extracción de cambios se cierra sin fusionarse, el resumen sabe que debe reabrirse antes de que la configuración pueda considerarse finalizada.
