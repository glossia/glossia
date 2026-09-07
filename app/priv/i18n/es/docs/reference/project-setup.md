%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "Referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario seleccione un repositorio y al menos un idioma objetivo en el flujo de **Nuevo proyecto**.

## Prerrequisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Descripción | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Seguir el progreso o salir de la página y volver más tarde. |
| **En ejecución** | Glossia está inspeccionando y actualizando el repositorio. | Seguir la actividad en vivo. |
| **Completado** | La base de localización se preparó y se publicó para revisión. | Abrir, revisar y fusionar la solicitud de extracción. |

Los proyectos son provisionales mientras la configuración esté en estado **Pendiente** o **En ejecución**. Si la configuración no puede finalizar o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio queda entonces disponible en el flujo de **Nuevo proyecto** para que la configuración pueda intentarse nuevamente.

## Progreso visible

La tarjeta de configuración sigue disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Un distintivo de estado y una barra de progreso.
- Una explicación breve del estado actual.
- Actividad reciente de preparación, inspección, cambios en archivos, verificación y finalización del repositorio.
- Un mensaje de fallo claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso de configuración visible.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la base de localización generada, incluyendo el contexto de `GLOSSIA.md` y los cambios prácticos más pequeños necesarios para cargar el contenido localizado.

La configuración no publica catálogos de destino únicamente con encabezados. Cuando un marco de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes de fuente extraídas con valores de traducción vacíos. Cuando los catálogos de destino no son requeridos aún, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y la fusionan mediante su proceso normal de GitHub.

La vista general del proyecto muestra un aviso de configuración mientras esta solicitud de extracción esté abierta. El aviso se elimina después de que la solicitud de extracción se haya fusionado. Si la solicitud de extracción se cierra sin fusionarse, la vista general explica que debe reabrirse antes de que la configuración pueda considerarse finalizada.