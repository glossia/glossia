%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "Referencia",
  section: "translation",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Después de que un usuario selecciona un repositorio en el **Nuevo proyecto** flujo, eligen uno de dos modos de configuración.

## Modos de configuración

| Modo | Qué hace Glossia | Cuándo elegirlo |
|---|---|---|
| **Configuración automática** | Inspecciona el repositorio y abre una solicitud de extracción con la configuración generada `L10N.md` configuración para los idiomas objetivo seleccionados. | El repositorio aún no tiene una configuración de localización. |
| **Configuración manual** | Crea el proyecto inmediatamente. No inspecciona el repositorio, ni lo modifica, ni abre una solicitud de extracción. | El repositorio ya tiene un `L10N.md` archivo, o un mantenedor lo escribirá. |

Los estados, la información de progreso y la solicitud de extracción descritos a continuación solo se aplican a la configuración automática.

## Configuración manual

Un proyecto configurado manualmente no tiene estado de configuración. Es utilizable tan pronto como se crea y nunca se descarta por una configuración fallida.

Glossia inicia una sesión de traducción en el siguiente empuje a la rama predeterminada del repositorio. La sesión traduce a cada destino declarado en el repositorio [`L10N.md`](/docs/reference/l10n-md) archivos, porque no se han seleccionado idiomas objetivo en la **Nuevo proyecto** flujo.

Hasta la primera sesión de traducción, la vista general del proyecto muestra un aviso que explica que Glossia está esperando un empuje que incluya un `L10N.md` archivo.

## Requisitos previos

- La cuenta tiene al menos un modelo configurado.
- La aplicación GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Para la configuración automática, debe seleccionarse al menos un idioma objetivo.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está a la espera de comenzar. | Sigue el progreso o sal de la página para volver más tarde. |
| **Ejecutando** | Glossia está inspeccionando y actualizando el repositorio. | Sigue la actividad en tiempo real. |
| **Completada** | La línea base de localización ha sido preparada y publicada para revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras la configuración está **Pendiente** o **en ejecución**. Si la configuración no puede finalizar o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio queda entonces disponible en el **Nuevo proyecto** flujo para que la configuración pueda intentarse de nuevo.

## Progreso visible

La tarjeta de configuración sigue disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Una insignia de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación, inspección, cambio de archivo, verificación y finalización del repositorio.
- Un mensaje de error claro cuando la configuración no se puede completar.

El progreso se almacena mientras el proyecto provisional existe. Un fallo terminal descarta tanto el proyecto como su progreso de configuración visible.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` contexto y los cambios prácticos mínimos necesarios para cargar contenido localizado.

La configuración no publica los catálogos de destino que solo contienen encabezados. Cuando un marco de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes extraídas del origen con valores de traducción vacíos. Cuando los catálogos de destino aún no se requieren, la configuración los deja para la primera ejecución de la traducción.

Glossia no fusiona la solicitud de fusión. Los mantenedores del repositorio la revisan y fusionan a través de su proceso habitual de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras esta solicitud de fusión está abierta. El aviso se elimina después de que se fusiona la solicitud de fusión. Si la solicitud de fusión se cierra sin fusionarse, el resumen explica que debe reabrirse antes de que la configuración pueda considerarse finalizada.