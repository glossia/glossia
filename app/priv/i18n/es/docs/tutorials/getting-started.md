%{
  title: "Primeros pasos",
  summary: "Conectar un repositorio y preparar su primera configuración de localización.",
  category: "tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub a Glossia, elige sus primeros idiomas objetivo y prepara una base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas gestionar ajustes y proyectos.
- Un repositorio de GitHub al que puedas conceder permisos a la aplicación GitHub de Glossia para lectura y actualización.
- Una clave del proveedor para un [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) compatible.

## 1\. Configurar un modelo de cuenta

Abre **Ajustes**, luego **Modelos**, y selecciona **Nuevo modelo**.

1. Asigna un nombre corto al modelo, como `translation-default`.
2. Abre el selector de modelos y escribe parte del nombre de un proveedor o modelo para filtrar la lista.
3. Selecciona el modelo que quieras que use Glossia.
4. Introduce la clave del proveedor y guarda el modelo.

El nombre corto permite que los repositorios se refieran a este modelo de cuenta sin colocar credenciales del proveedor en control de versiones. Consulta [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Iniciar un proyecto

Vuelve a **Proyectos** y selecciona **Nuevo proyecto**.

Si Glossia pregunta por el acceso al repositorio, sigue el enlace a GitHub y concede acceso de la aplicación GitHub de Glossia al repositorio. Después de volver a Glossia, reabre **Nuevo proyecto** si es necesario.

## 3\. Elegir un repositorio

Selecciona el repositorio que quieras localizar. Glossia solo lista los repositorios disponibles a través de la instalación de la aplicación GitHub de la cuenta actual.

Continúa al paso de idiomas.

## 4\. Elegir idiomas objetivo

Selecciona uno o más idiomas que deban producirse a partir del contenido de origen del repositorio, y inicia la configuración.

## 5\. Seguir el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de los archivos, los cambios, las comprobaciones y la finalización.

Puedes salir de la página y volver a la vista general del proyecto sin perder el estado de configuración. Si la configuración falla, la misma tarjeta explica lo que requiere atención y ofrece **Reintentar configuración**.

## 6\. Revisar el resultado

Cuando la configuración finalice, abre la vista general del proyecto y revisa la solicitud de extracción creada para el repositorio. La base propuesta normalmente incluye:

- Un archivo raíz `GLOSSIA.md` con el lenguaje de origen, las rutas de origen y los idiomas objetivo.
- Los cambios de aplicación o contenido mínimos necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estaba disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo habitual de GitHub. Las ejecuciones futuras de traducción utilizan el contexto de `GLOSSIA.md` fusionado.

La vista general del proyecto mantiene visible la solicitud de extracción de configuración hasta que se fusiona. Si se cierra sin ser fusionada, vuélvela a abrir desde el enlace en el aviso de configuración.

## Próximos pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Entender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)