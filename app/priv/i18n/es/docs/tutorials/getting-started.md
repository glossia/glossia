%{
  title: "Comenzando",
  summary: "Conecte un repositorio y prepare su primera configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, elige sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas gestionar ajustes y proyectos.
- Un repositorio de GitHub al que puedas otorgar a la GitHub App de Glossia permisos para leer y actualizar.
- Una clave del proveedor para un [modelo de lenguaje grande compatible](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configura un modelo de cuenta

Abre **Configuración**, luego **Modelos**, y selecciona **Nuevo modelo**.

1. Asigne un nombre corto al modelo, como `translation-default`.
2. Abra el selector de modelos e introduzca parte del nombre de un proveedor o modelo para filtrar la lista.
3. Seleccione el modelo que desea que Glossia use.
4. Ingrese la clave del proveedor y guarde el modelo.

El nombre corto permite a los repositorios referirse a este modelo de cuenta sin incluir credenciales del proveedor en el control de versiones. Consulte [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Comenzar un proyecto

Volver a **Proyectos** y seleccionar **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y conceda el acceso de la aplicación de GitHub de Glossia al repositorio. Después de volver a Glossia, vuelva a abrir **Nuevo proyecto** si es necesario.

## 3\. Elegir un repositorio

Selecciona el repositorio que deseas traducir. Glossia solo muestra los repositorios disponibles a través de la instalación de la GitHub App de la cuenta actual.

Continuar al paso de idiomas.

## 4\. Elegir idiomas destino

Selecciona uno o más idiomas que se generarán a partir del contenido fuente del repositorio e inicia la configuración.

## 5\. Seguir el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las verificaciones y la finalización.

Puede dejar la página y volver a la vista general del proyecto sin perder el estado de configuración. Si la configuración falla, la misma tarjeta explica lo que necesita atención y ofrece **Reintentar la configuración**.

## 6\. Revisar el resultado

Cuando la configuración finalice, abra la vista general del proyecto y revise la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Un archivo raíz `L10N.md` archivo con idioma fuente, rutas de origen y lenguas objetivo.
- Los cambios mínimos de aplicación o contenido necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estaba disponible en el repositorio.

Revise y fusione la solicitud de extracción a través de su flujo de trabajo habitual de GitHub. Las futuras sesiones de traducción utilizan la fusionada `L10N.md` contexto.

La vista general del proyecto mantiene visible la solicitud de extracción de configuración hasta que se fusiona. Si se cierra sin fusionarse, vuelva a abrirla desde el enlace en la notificación de configuración.

## Próximos pasos

- [Agregar un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprenda cómo funcionan los modelos de cuenta](/docs/explanation/account-models)