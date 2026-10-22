%{
  title: "Primeros pasos",
  summary: "Conecte un repositorio y prepare su primera configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---

Este tutorial conecta un repositorio de GitHub a Glossia, elige sus primeros idiomas objetivo y prepara una base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas administrar la configuración y los proyectos.
- Un repositorio de GitHub en el que puedas conceder la Aplicación GitHub de Glossia permisos de lectura y actualización.
- Una clave de proveedor para un [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) soportado.

## 1. Configurar un modelo de cuenta

Abre **Configuración**, luego **Modelos** y selecciona **Nuevo modelo**.

1. Asigna al modelo un nombre corto, como `translation-default`.
2. Abre el selector de modelos e introduce parte de un nombre de proveedor o modelo para filtrar la lista.
3. Selecciona el modelo que deseas que utilice Glossia.
4. Introduce la clave del proveedor y guarda el modelo.

El identificador permite que los repositorios hagan referencia a este modelo de cuenta sin colocar las credenciales del proveedor en el control de origen. Consulta [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider) para más detalles.

## 2. Iniciar un proyecto

Vuelve a **Proyectos** y selecciona **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, sigue el enlace a GitHub y concede a la Aplicación GitHub de Glossia acceso al repositorio. Al volver a Glossia, vuelve a abrir **Nuevo proyecto** si es necesario.

## 3. Elegir un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo lista los repositorios disponibles a través de la instalación de la Aplicación GitHub de la cuenta actual.

## 4. Elegir cómo configurar el proyecto

Selecciona **Configuración automatizada** para que Glossia inspeccione el repositorio y proponga la configuración de localización en una solicitud de extracción. Este tutorial sigue esa ruta.

Si el repositorio ya tiene un `L10N.md` archivo, o prefieres escribirlo tú mismo, selecciona **Configuración manual** en su lugar. Glossia crea el proyecto inmediatamente y puedes saltarte los pasos restantes. Consulta [Configuración del proyecto](/docs/reference/project-setup) para ver qué hace cada modo.

## 5. Elegir idiomas objetivo

Selecciona uno o más idiomas que deben generarse a partir del contenido fuente del repositorio y luego inicia la configuración.

## 6. Seguir el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las comprobaciones y la finalización.

Puedes salir de la página y volver a la vista general del proyecto sin perder el estado de configuración. Si la configuración falla, lee el aviso de fallo. Glossia descarta el proyecto provisional; corrige el prerrequisito e inicia de nuevo a través de **Nuevo proyecto**. Consulta [Reintentar la configuración del proyecto](/docs/how-to/retry-project-setup).

## La vista general del proyecto mantiene la solicitud de extracción de configuración visible hasta que se fusiona. Si se cierra sin fusionarse, vuelve a abrirla desde el enlace en el aviso de configuración.

Cuando la configuración finaliza, abre la vista general del proyecto y revisa la solicitud de extracción creada para el repositorio. La base propuesta normalmente incluye:

- Un archivo raíz `L10N.md` con el idioma fuente, las rutas del origen y los idiomas objetivo.
- Los cambios de aplicación o contenido mínimos necesarios para cargar archivos localizados.
- Cualquiera validación ligera que ya estuviera disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo normal de GitHub. Las futuras ejecuciones de traducción utilizan el `L10N.md` contexto fusionado.

La vista general del proyecto mantiene la solicitud de extracción de configuración visible hasta que se fusiona. Si se cierra sin fusionarse, vuelve a abrirla desde el enlace en el aviso de configuración.

## Siguientes pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)
