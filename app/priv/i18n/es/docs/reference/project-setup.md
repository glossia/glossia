%{
  title: "Configuración del proyecto",
  summary: "Estados, información de progreso y resultados de la configuración del repositorio.",
  category: "reference",
  order: 2
}
---
La configuración del proyecto prepara un repositorio conectado para Glossia. Comienza después de que un usuario selecciona un repositorio y al menos un idioma de destino en el flujo **Nuevo proyecto**.

## Requisitos previos

- La cuenta tiene al menos un modelo configurado.
- La aplicación de GitHub de Glossia puede acceder al repositorio seleccionado.
- El usuario puede crear proyectos en la cuenta.
- Se ha seleccionado al menos un idioma de destino.

## Estados

| Estado | Significado | Acción disponible |
|---|---|---|
| **Pendiente** | El proyecto se ha aceptado y está esperando para comenzar. | Siga el progreso o salga de la página y vuelva más tarde. |
| **En curso** | Glossia está inspeccionando y actualizando el repositorio. | Siga la actividad en directo. |
| **Completado** | La base de localización se preparó y publicó para su revisión. | Abra, revise y fusione la solicitud de cambios. |

Los proyectos son provisionales mientras la configuración está **Pendiente** o **En curso**. Si la configuración no puede finalizar o publicar un cambio utilizable, Glossia limpia el entorno de configuración y elimina el proyecto provisional. El repositorio vuelve a estar disponible en el flujo **Nuevo proyecto** para que se pueda intentar de nuevo la configuración.

## Progreso visible

La tarjeta de configuración permanece disponible en el flujo de nuevo proyecto y en la vista general del proyecto. Incluye:

- Una insignia de estado y una barra de progreso.
- Una breve explicación del estado actual.
- Actividad reciente de preparación e inspección del repositorio, cambios de archivos, comprobaciones y finalización.
- Un mensaje de error claro cuando la configuración no puede completarse.

El progreso se almacena mientras existe el proyecto provisional. Un error definitivo descarta tanto el proyecto como el progreso visible de su configuración.

## Resultado completado

Una configuración conectada correcta crea una rama específica y una solicitud de cambios dirigida a la rama predeterminada del repositorio. La solicitud de cambios contiene la base de localización generada, incluido el contexto `GLOSSIA.md`, y los cambios mínimos necesarios para cargar contenido localizado.

La configuración no publica catálogos de destino que solo contengan encabezados. Cuando un marco de localización requiere catálogos de destino antes de la traducción, los catálogos contienen las entradas de mensajes extraídas del origen con valores de traducción vacíos. Cuando los catálogos de destino aún no son necesarios, la configuración los deja para la primera ejecución de traducción.

Glossia no fusiona la solicitud de cambios. Los responsables del repositorio la revisan y fusionan mediante su proceso habitual de GitHub.

La vista general del proyecto muestra un aviso de configuración mientras esta solicitud de cambios permanezca abierta. El aviso se elimina después de que la solicitud de cambios se fusione. Si la solicitud de cambios se cierra sin fusionarse, la vista general explica que debe volver a abrirse antes de que la configuración pueda considerarse finalizada.