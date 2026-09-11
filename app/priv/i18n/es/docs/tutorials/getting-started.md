%{
  title: "Primeros pasos",
  summary:
    "Conectar un repositorio y preparar su primera sesión de configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, elige sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedes gestionar configuraciones y proyectos.
- Un repositorio de GitHub en el que puedes otorgar permisos de lectura y actualización a la aplicación GitHub de Glossia.
- Una clave de proveedor para un soportado [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurar un modelo de cuenta

Abrir **Configuración**, luego **Modelos**, y selecciona **Nuevo modelo**.

1. Asigna un nombre corto al modelo, tal como `translation-default`.
2. Abre el selector de modelos y escribe parte del nombre del proveedor o modelo para filtrar la lista.
3. Selecciona el modelo que deseas que Glossia utilice.
4. Introduce la clave del proveedor y guarda el modelo.

El nombre corto permite que los repositorios se refieran a este modelo de la cuenta sin colocar las credenciales del proveedor en el control de versiones. Ver [Configura un proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Iniciar un proyecto

Volver a **Proyectos** y seleccionar **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y otorgue el acceso de la App de GitHub de Glossia al repositorio. Después de volver a Glossia, vuelva a abrir **Nuevo proyecto** si es necesario.

## 3\. Elige un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo lista los repositorios disponibles a través de la instalación de la aplicación de GitHub de la cuenta actual.

Continuar al paso de idiomas.

## 4\. Elige los idiomas objetivo

Selecciona uno o más idiomas que deben generarse a partir del contenido fuente del repositorio, luego inicia la sesión de configuración.

## 5\. Sigue el progreso de la sesión de configuración.

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y las actividades recientes, incluida la preparación del repositorio, la inspección de archivos, los cambios, las comprobaciones y la finalización.

Puede abandonar la página y volver al resumen del proyecto sin perder el estado de la configuración. Si la configuración falla, la misma tarjeta explica lo que necesita atención y ofrece **Reintentar configuración**.

## 6\. Revisar los resultados

Cuando finaliza la configuración, abra el resumen del proyecto y revise la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Una raíz `L10N.md` archivo con lenguaje fuente, rutas de origen y lenguajes objetivo.
- Los cambios de aplicación o contenido mínimos necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estaba disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo normal de GitHub. Las futuras ejecuciones de traducción utilizan la versión fusionada `L10N.md` contexto.

La vista general del proyecto mantiene visible la solicitud de extracción de configuración hasta que se integre. Si se cierra sin integrarse, vuelve a abrirla desde el enlace en el aviso de configuración.

## Próximos pasos

- [Agregar un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprende los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprende cómo funcionan los modelos de cuenta](/docs/explanation/account-models)