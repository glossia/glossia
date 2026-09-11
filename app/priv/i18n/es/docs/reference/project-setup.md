%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "Referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario seleccione un repositorio y al menos un idioma objetivo en el **Nuevo proyecto** flujo.

## Prerrequisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Seguir el progreso o salir de la página y volver más tarde. |
| **En curso** | Glossia está inspeccionando y actualizando el repositorio. | Sigue la actividad en vivo. |
| **Completado** | La línea base de localización fue preparada y publicada para revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras la sesión de configuración está **Pendiente** o **En ejecución**. Si la configuración no puede completarse o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio entonces se vuelve disponible en la **Nuevo proyecto** flujo para intentar la configuración nuevamente.

## Progreso visible

La tarjeta de configuración sigue disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Una insignia de estado y barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación del repositorio, inspección, cambios de archivo, verificación y finalización.
- Un mensaje de error claro cuando la configuración no puede completarse.

El progreso se almacena mientras exista el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` el contexto y los cambios prácticos más pequeños necesarios para cargar contenido localizado.

La configuración no publica catálogos de destino únicamente con encabezados. Cuando un marco de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes de origen extraídas con valores de traducción vacíos. Cuando los catálogos de destino no se requieren aún, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio revisan y la fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras esta solicitud de extracción está abierta. El aviso se elimina después de que la solicitud de extracción se fusiona. Si la solicitud de extracción se cierra sin fusionarse, el resumen explica que debe volver a abrirse antes de que la configuración pueda considerarse finalizada.