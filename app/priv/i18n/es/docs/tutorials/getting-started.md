%{
  title: "Primeros pasos",
  summary: "Conectar un repositorio y preparar su primera configuración de localización.",
  category: "tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, elige sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de empezar

Necesitas:

- Una cuenta de Glossia donde puedas gestionar configuraciones y proyectos.
- Un repositorio de GitHub en el que puedas conceder permisos a la GitHub App de Glossia para leer y actualizar.
- Una clave de proveedor para un soportado [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurar un modelo de cuenta

Abrir **Configuración**, luego **Modelos**, y seleccionar **Nuevo modelo**.

1. Asigna un nombre corto al modelo, por ejemplo `translation-default`,
2. Abre el selector de modelos y escribe parte del nombre del proveedor o modelo para filtrar la lista.
3. Selecciona el modelo que deseas que Glossia utilice.
4. Introduce la clave del proveedor y guarda el modelo.

El nombre corto permite que los repositorios se refieran a este modelo de cuenta sin colocar credenciales del proveedor en el control de versiones. Consulta [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Iniciar un proyecto

Volver a **Proyectos** y seleccionar **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y conceda acceso a la Glossia GitHub App al repositorio. Tras volver a Glossia, vuelva a abrir **Nuevo proyecto** si es necesario.

## 3\. Elegir un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo lista los repositorios disponibles a través de la instalación de la GitHub App de la cuenta actual.

## 4\. Elegir cómo configurar el proyecto

Seleccionar **Configuración automática** para permitir que Glossia examine el repositorio y proponga la configuración de localización en una pull request. Este tutorial sigue ese camino.

Si el repositorio ya tiene un `L10N.md` archivo, o si prefieres escribirlo tú mismo, selecciona **Configuración manual** en su lugar. Glossia crea el proyecto de inmediato y puedes omitir los pasos restantes. Ver [Configuración del proyecto](/docs/reference/project-setup) para ver qué hace cada modo.

## 5\. Elige los idiomas objetivo

Selecciona uno o más idiomas que deban generarse a partir del contenido de origen del repositorio y luego inicia la configuración.

## 6\. Sigue el progreso de la configuración

Mantenga la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las comprobaciones y la finalización.

Puede salir de la página y volver a la vista general del proyecto sin perder el estado de la configuración. Si la configuración falla, lea el aviso de error. Glossia descarta el proyecto provisional; corrige el requisito previo e inicie de nuevo a través de **Nuevo proyecto**. Vea [Reintentar la configuración del proyecto](/docs/how-to/retry-project-setup).

## 7\. Revisar el resultado

Cuando se complete la configuración, abra la vista general del proyecto y revise la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Una raíz `L10N.md` archivo con idioma de origen, rutas de origen e idiomas objetivo.
- Las modificaciones mínimas de aplicación o contenido necesarias para cargar archivos localizados.
- Cualquier validación liviana que ya estuviera disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo normal de GitHub. Las futuras ejecuciones de traducción utilizan el `L10N.md` contexto.

La vista general del proyecto mantiene la solicitud de configuración visible hasta que se fusiona. Si se cierra sin fusionar, ábrela de nuevo desde el enlace en el aviso de configuración.

## Próximos pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)