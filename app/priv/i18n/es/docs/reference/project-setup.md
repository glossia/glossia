%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso, y resultados de la configuración del repositorio.",
  category: "Referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario seleccione un repositorio y al menos un idioma objetivo en el **Nuevo proyecto** flujo.

## Prerrequisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Descripción | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Sigue el progreso o abandona la página y vuelve más tarde. |
| **En ejecución** | Glossia está inspeccionando y actualizando el repositorio. | Sigue la actividad en vivo. |
| **Completado** | La línea base de localización se preparó y publicó para revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras la sesión de configuración está **Pendiente** o **En ejecución**. Si la configuración no puede finalizar o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio pasa a estar disponible en el **Nuevo proyecto** flujo de modo que la configuración pueda intentarse de nuevo.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo del nuevo proyecto y en el resumen del proyecto. Incluye:

- Un distintivo de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación del repositorio, inspección, cambios de archivo, verificación y finalización.
- Un mensaje de error claro cuando la sesión de configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de la sesión de configuración.

## Resultado completado

Una sesión de configuración conectada con éxito crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` el contexto y los cambios prácticos mínimos necesarios para cargar contenido localizado.

La sesión de configuración no publica catálogos de destino con solo encabezados. Cuando un marco de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes de origen extraídas con valores de traducción vacíos. Cuando los catálogos de destino no se requieren aún, la sesión de configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y fusionan a través de su proceso habitual de GitHub.

El resumen del proyecto muestra un aviso de la sesión de configuración mientras esta solicitud de extracción esté abierta. El aviso se elimina después de fusionar la solicitud de extracción. Si la solicitud de extracción se cierra sin fusionarse, el resumen explica que debe reabrirse antes de que la sesión de configuración pueda considerarse finalizada.