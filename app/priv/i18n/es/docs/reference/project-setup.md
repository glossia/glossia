%{
  title: "Configuración del proyecto",
  summary:
    "Estados, información sobre el progreso y resultados de la configuración del repositorio.",
  category: "referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario selecciona un repositorio y al menos un idioma objetivo en el **Nuevo proyecto** flujo.

## Prerrequisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Significado | Acción disponible |
|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está a la espera de comenzar. | Siga el progreso o salga de la página y regrese más tarde. |
| **Ejecutando** | Glossia está inspeccionando y actualizando el repositorio. | Observa la actividad en vivo. |
| **Completado** | La línea base de localización fue preparada y publicada para revisión. | Abre, revisa y fusiona el pull request. |

Los proyectos son provisionales mientras la configuración está **Pendiente** o **En ejecución**. Sin embargo, si la configuración no puede terminar o publicar un cambio util, Glossia limpia el entorno de configuracion y elimina el proyecto provisional. El repositorio entonces queda disponible en el **Nuevo proyecto** flujo para que pueda intentarse nuevamente la configuracion.

## Progreso visible

La tarjeta de configuracion sigue disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Una insignia de estado y una barra de progreso.
- Una breve explicacion del estado actual.
- Actividad reciente de preparacion del repositorio, inspeccion, cambio de archivo, verificacion y finalizacion.
- Un mensaje de error claro cuando la configuración no pueda completarse.

El progreso se almacena mientras exista el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de la configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama por defecto del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` contexto y los cambios prácticos mínimos necesarios para cargar el contenido localizado.

La configuración no publica catálogos de destino solo con encabezados. Cuando un framework de localización requiere catálogos de destino antes de la traducción, estos contienen las entradas de mensajes fuente extraídas con valores de traducción vacíos. Cuando los catálogos de destino no son necesarios todavía, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y la fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras se mantiene abierta esta solicitud de extracción. El aviso se elimina después de que se fusione la solicitud de extracción. Si la solicitud de extracción se cierra sin fusionarse, el resumen explica que debe volver a abrirse antes de que la configuración pueda considerarse finalizada.