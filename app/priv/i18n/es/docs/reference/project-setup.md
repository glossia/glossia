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
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Al menos un idioma objetivo está seleccionado.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto ha sido aceptado y está esperando comenzar. | Siga el progreso o abandone la página y regrese más tarde. |
| **En ejecución** | Glossia está inspeccionando y actualizando el repositorio. | Sigue la actividad en vivo. |
| **Completado** | La línea base de localización fue preparada y publicada para su revisión. | Abre, revisa y fusiona la solicitud de extracción. |

Los proyectos son provisionales mientras que la sesión de configuración está **Pendiente** o **En ejecución**. Si la configuración no puede finalizar o publicar un cambio útil, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio se vuelve disponible en el **Nuevo proyecto** flujo para que la configuración pueda intentarse de nuevo.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Un distintivo de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación, inspección, modificación de archivos, verificación y finalización.
- Un mensaje claro de error cuando la configuración no puede completarse.

El progreso se almacena mientras exista el proyecto provisional. Un error fatal descarta tanto el proyecto como su progreso visible de configuración.

## Resultado completado

Una configuración conectada exitosa crea una rama dedicada y una solicitud de extracción contra la rama predeterminada del repositorio. La solicitud de extracción contiene la línea base de localización generada, incluyendo `L10N.md` el contexto y las modificaciones prácticas más pequeñas necesarias para cargar contenido localizado.

La configuración no publica catálogos objetivo solo de encabezados. Cuando un marco de localización requiere catálogos objetivo antes de la traducción, los catálogos contienen las entradas de mensajes de origen extraídas con valores de traducción vacíos. Cuando los catálogos objetivo no son necesarios aún, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de extracción. Los mantenedores del repositorio revisan y fusionan a través de su proceso normal de GitHub.

La vista general del proyecto muestra un aviso de configuración mientras esta solicitud de extracción está abierta. El aviso se elimina después de que se fusiona la solicitud de extracción. Si la solicitud de extracción se cierra sin fusionarse, la vista general explica que debe volver a abrirse antes de que la configuración pueda considerarse finalizada.