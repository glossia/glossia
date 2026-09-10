%{
  title: "Comenzar",
  summary: "Conectar un repositorio y preparar su primera configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, elige sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas gestionar la configuración y los proyectos.
- Un repositorio de GitHub en el que puedas otorgar permiso al Glossia GitHub App para leer y actualizar.
- Una clave de proveedor para un soportado [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configura un modelo de cuenta

Abre **Configuración**, luego **Modelos**, y selecciona **Nuevo modelo**.

1. Asigne un identificador corto al modelo, como `translation-default`.
2. Abra el selector de modelos y escriba parte del nombre del proveedor o modelo para filtrar la lista.
3. Seleccione el modelo que desea que Glossia utilice.
4. Ingrese la clave del proveedor y guarde el modelo.

El identificador permite a los repositorios hacer referencia a este modelo de cuenta sin colocar las credenciales del proveedor en el control de versiones. Vea [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) más detalles.

## 2\. Inicie un proyecto

Volver a **Proyectos** y seleccione **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y otorgue acceso al repositorio a la aplicación de GitHub de Glossia. Después de volver a Glossia, vuelva a abrir **Nuevo proyecto** si es necesario.

## 3\. Elegir un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo lista repositorios disponibles a través de la instalación de la aplicación GitHub de tu cuenta actual.

Continuar al paso de idioma.

## 4\. Elegir idiomas objetivo

Selecciona uno o más idiomas que se deben generar a partir del contenido fuente del repositorio y luego inicia la configuración.

## 5\. Seguir el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las comprobaciones y la finalización.

Puede salir de la página y volver al resumen del proyecto sin perder el estado de configuración. Si la configuración falla, la misma tarjeta explica qué necesita atención y ofrece **Reintentar configuración**,

## 6\. Revisar el resultado

Cuando se complete la configuración, abra el resumen del proyecto y revise la solicitud de integración creada para el repositorio. La línea base propuesta normalmente incluye:

- A raíz `L10N.md` archivo con el idioma fuente, las rutas de origen y los idiomas objetivo.
- Los cambios más pequeños en la aplicación o el contenido necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estuviera disponible en el repositorio.

Revisar y fusionar la solicitud de extracción a través de tu flujo de trabajo habitual de GitHub. Las futuras ejecuciones de traducción usan la fusionada `L10N.md` contexto.

La vista general del proyecto mantiene visible la solicitud de extracción de configuración hasta que se fusiona. Si se cierra sin fusionarse, ábreala de nuevo desde el enlace en el aviso de configuración.

## Próximos pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)