%{
  title: "Primeros pasos",
  summary: "Conectar un repositorio y preparar su primera configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---

Este tutorial conecta un repositorio de GitHub a Glossia, selecciona sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas administrar ajustes y proyectos.
- Un repositorio de GitHub en el que puedas otorgar a la aplicación GitHub de Glossia permisos de lectura y actualización.
- Una clave de proveedor para un [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) compatible.

## 1. Configurar un modelo de cuenta

Abre **Ajustes**, luego **Modelos** y selecciona **Nuevo modelo**.

1. Proporciona al modelo un identificador corto, como `translation-default`.
2. Abre el selector de modelos y escribe parte del nombre de un proveedor o modelo para filtrar la lista.
3. Selecciona el modelo que deseas que Glossia utilice.
4. Introduce la clave del proveedor y guarda el modelo.

El identificador permite a los repositorios referirse a este modelo de cuenta sin colocar credenciales del proveedor en el control de código fuente. Consulta [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider) para más detalles.

## 2. Iniciar un proyecto

Regresa a **Proyectos** y selecciona **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, sigue el enlace a GitHub y otorga acceso al repositorio a la aplicación GitHub de Glossia. Después de volver a Glossia, vuelve a abrir **Nuevo proyecto** si es necesario.

## 3. Elegir un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo enumera los repositorios disponibles mediante la instalación de la aplicación GitHub de la cuenta actual.

## 4. Elegir cómo configurar el proyecto

Selecciona **Configuración automatizada** para permitir que Glossia examine el repositorio y proponga la configuración de localización en una solicitud de extracción. Este tutorial sigue ese camino.

Si el repositorio ya tiene un archivo `L10N.md` o prefieres escribirlo tú mismo, selecciona **Configuración manual** en su lugar. Glossia crea el proyecto inmediatamente y puedes omitir los pasos restantes. Consulta [Configuración de proyecto](/docs/reference/project-setup) para ver lo que hace cada modo.

## 5. Elegir idiomas objetivo

Selecciona uno o más idiomas que deben generarse a partir del contenido fuente del repositorio, luego inicia la configuración.

## 6. Seguir el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, inspección de archivos, cambios, comprobaciones y finalización.

Puedes salir de la página y volver a la vista general del proyecto sin perder el estado de configuración. Si la configuración falla, lee el aviso de fallo. Glossia descarta el proyecto provisional; corrige el prerrequisito y comienza de nuevo a través de **Nuevo proyecto**. Consulta [Reintentar configuración de proyecto](/docs/how-to/retry-project-setup).

## 7. Revisar los resultados

Cuando la configuración finaliza, abre la vista general del proyecto y revisa la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Un archivo raíz `L10N.md` con idioma fuente, rutas de origen e idiomas objetivo.
- Los cambios de aplicación o contenido más pequeños necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estuviera disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo normal de GitHub. Las futuras ejecuciones de traducción utilizan el contexto `L10N.md` fusionado.

La vista general del proyecto mantiene visible la solicitud de extracción de configuración hasta que se fusiona. Si se cierra sin fusionarse, ábrelo desde el enlace en el aviso de configuración.

## Próximos pasos

- [Agregar un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)
