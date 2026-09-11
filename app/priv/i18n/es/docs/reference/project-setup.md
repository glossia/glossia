%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso, y resultados de la configuración del repositorio.",
  category: "referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario seleccione un repositorio y al menos un idioma objetivo en el **Nuevo proyecto** flujo.

## Requisitos previos

- La cuenta tiene al menos un modelo configurado.
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Seguir el progreso o salir de la página y volver más tarde. |
| **En ejecución** | Glossia está inspeccionando y actualizando el repositorio. | Siga la actividad en vivo. |
| **Completado** | La línea base de localización fue preparada y publicada para su revisión. | Abra, revise y fusione la solicitud de extracción. |

Los proyectos son provisionales mientras la configuración está **Pendiente** o **En ejecución**. Si la configuración no puede finalizar ni publicar un cambio aplicable, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio queda disponible en el **Nuevo proyecto** flujo para intentar la configuración nuevamente.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo de nuevo proyecto y en el resumen del proyecto. Incluye:

- Un distintivo de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación del repositorio, inspección, cambios de archivos, verificación y finalización.
- Un mensaje de error claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un error terminal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo, `L10N.md` contexto y los cambios prácticos más pequeños necesarios para cargar contenido localizado.

La configuración no publica catálogos objetivo solo con encabezados. Cuando un marco de localización requiere catálogos objetivo antes de la traducción, los catálogos contienen las entradas de mensajes fuente extraídas con valores de traducción vacíos. Cuando los catálogos objetivo aún no son necesarios, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra una notificación de configuración mientras esta solicitud de extracción está abierta. La notificación se elimina después de que se haya fusionado la solicitud de extracción. Si se cierra la solicitud de extracción sin fusionarla, el resumen explica que debe volver a abrirse antes de que la configuración pueda considerarse finalizada.