%{
  title: "Primeros pasos",
  summary: "Conecte un repositorio y prepare su primera configuración de localización.",
  category: "tutoriales",
  order: 1
}
---
Esta tutoría conecta un repositorio de GitHub con Glossia, elige sus primeros idiomas objetivo y prepara una línea base de localización para que tu equipo la revise.

## Antes de comenzar

Necesitas:

- Una cuenta de Glossia donde puedas gestionar configuraciones y proyectos.
- Un repositorio de GitHub en el que puedas conceder permiso a la aplicación de GitHub App de Glossia para leer y actualizar.
- Una clave de proveedor para un soportado [modelo de lenguaje a gran escala](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurar un modelo de cuenta

Abrir **Configuración**, luego **Modelos**, y seleccionar **Nuevo modelo**.

1. Asigne un identificador corto al modelo, tal como `translation-default`.
2. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
3. Seleccione el modelo que desea que Glossia utilice.
4. Ingrese la clave del proveedor y guarde el modelo.

El identificador permite que los repositorios hagan referencia a este modelo de cuenta sin colocar las credenciales del proveedor en el control de código fuente. Consulte [Configure un proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Iniciar un proyecto

Volver a **Proyectos** y seleccionar **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y conceda acceso a la aplicación GitHub de Glossia al repositorio. Al volver a Glossia, vuelva a abrir **Nuevo proyecto** Si es necesario.

## 3\. Elija un repositorio

Seleccione el repositorio que desea localizar. Glossia solo enumera los repositorios disponibles a través de la instalación de la aplicación de GitHub de la cuenta actual.

Continúe al paso del idioma.

## 4\. Elija los idiomas objetivo

Seleccione uno o más idiomas que se generarán a partir del contenido fuente del repositorio, luego inicie la configuración.

## 5\. Siga el progreso de la configuración

Mantenga la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las verificaciones y la finalización.

Puede salir de la página y volver al resumen del proyecto sin perder el estado de configuración. Si la configuración falla, la misma tarjeta explica lo que necesita atención y ofrece **Reintentar configuración**.

## 6\. Revisar el resultado

Cuando la configuración se complete, abra el resumen del proyecto y revise la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Una raíz `L10N.md` archivo con idioma de origen, rutas de origen y idiomas de destino.
- Los cambios más pequeños en la aplicación o el contenido necesarios para cargar archivos localizados.
- Cualquier validación ligera que ya estaba disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo de trabajo habitual de GitHub. Las futuras sesiones de traducción utilizan el fusionado `L10N.md` contexto.

El resumen del proyecto mantiene la solicitud de extracción de configuración visible hasta que se fusiona. Si se cierra sin fusionarse, vuelve a abrirla desde el enlace en el aviso de configuración.

## Próximos pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprender cómo funcionan los modelos de cuenta](/docs/explanation/account-models)