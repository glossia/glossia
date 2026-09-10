%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "Referencia",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario selecciona un repositorio y al menos un idioma de destino en el **Nuevo proyecto** flujo.

## Requisitos

- La cuenta tiene al menos un modelo configurado.
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma de destino está seleccionado.

## Estados

| Estado | Meaning | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando para comenzar. | Siga el progreso o salga de la página y vuelva más tarde. |
| **En curso** | Glossia está inspeccionando y actualizando el repositorio. | Sigue la actividad en vivo. |
| **Completado** | La línea base de localización ha sido preparada y publicada para revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras la configuración esté **Pendiente** o **Ejecutando**. Si la configuración no puede finalizar o publicar un cambio utilizable, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio queda entonces disponible en el **Nuevo proyecto** flujo para que la configuración pueda intentarse de nuevo.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Una etiqueta de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación del repositorio, revisión, modificación de archivo, verificación y finalización.
- Un mensaje de error claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un fallo terminal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` contexto y las modificaciones prácticas más pequeñas necesarias para cargar contenido localizado.

La configuración no publica catálogos de destino con solo encabezados. Cuando un framework de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes de origen extraídas con valores de traducción vacíos. Cuando los catálogos de destino aún no son necesarios, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio la revisan y fusionan a través de su proceso normal de GitHub.

El resumen del proyecto muestra un aviso de configuración mientras esta solicitud de extracción está abierta. El aviso se elimina después de que la solicitud de extracción se fusiona. Si la solicitud de extracción se cierra sin fusionarse, el resumen explica que debe reabrirse antes de que la configuración pueda considerarse finalizada.