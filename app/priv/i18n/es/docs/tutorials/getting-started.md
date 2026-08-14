%{
  title: "Primeros pasos",
  summary: "Conecte un repositorio y prepare su primera configuración de localización.",
  category: "tutorials",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, selecciona sus primeros idiomas de destino y prepara una base de localización para que su equipo la revise.

## Antes de comenzar

Necesita:

- Una cuenta de Glossia en la que pueda gestionar la configuración y los proyectos.
- Un repositorio de GitHub al que pueda conceder permiso de lectura y actualización a la aplicación de GitHub de Glossia.
- Una clave de proveedor para un [modelo de lenguaje de gran tamaño](https://en.wikipedia.org/wiki/Large_language_model) compatible.

## 1. Configurar un modelo de cuenta

Abra **Configuración**, después **Modelos**, y seleccione **Nuevo modelo**.

1. Asigne al modelo un identificador corto, como `translation-default`.
2. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
3. Seleccione el modelo que desea que utilice Glossia.
4. Introduzca la clave del proveedor y guarde el modelo.

El identificador permite que los repositorios hagan referencia a este modelo de cuenta sin guardar las credenciales del proveedor en el control de versiones. Consulte [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) para obtener más información.

## 2. Iniciar un proyecto

Vuelva a **Proyectos** y seleccione **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y conceda a la aplicación de GitHub de Glossia acceso al repositorio. Después de volver a Glossia, abra de nuevo **Nuevo proyecto** si es necesario.

## 3. Elegir un repositorio

Seleccione el repositorio que desea localizar. Glossia solo muestra los repositorios disponibles mediante la instalación de la aplicación de GitHub de la cuenta actual.

Continúe con el paso de selección de idiomas.

## 4. Elegir los idiomas de destino

Seleccione uno o varios idiomas que deban generarse a partir del contenido de origen del repositorio y, después, inicie la configuración.

## 5. Seguir el progreso de la configuración

Mantenga abierta la página de configuración mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, los cambios, las comprobaciones y la finalización.

Puede salir de la página y volver a la vista general del proyecto sin perder el estado de la configuración. Si la configuración falla, la misma tarjeta explica qué requiere atención y ofrece la opción **Reintentar configuración**.

## 6. Revisar el resultado

Cuando finalice la configuración, abra la vista general del proyecto y revise la solicitud de incorporación de cambios creada para el repositorio. La base propuesta normalmente incluye:

- Un archivo `GLOSSIA.md` en la raíz con el idioma de origen, las rutas de origen y los idiomas de destino.
- Los cambios mínimos necesarios en la aplicación o el contenido para cargar los archivos localizados.
- Cualquier validación básica que ya estuviera disponible en el repositorio.

Revise y fusione la solicitud de incorporación de cambios mediante su flujo de trabajo habitual de GitHub. Las futuras ejecuciones de traducción utilizarán el contexto combinado de `GLOSSIA.md`.

La vista general del proyecto mantiene visible la solicitud de incorporación de cambios de configuración hasta que se fusione. Si se cierra sin fusionarla, vuelva a abrirla desde el enlace del aviso de configuración.

## Siguientes pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprender los estados de configuración de un proyecto](/docs/reference/project-setup)
- [Conocer el funcionamiento de los modelos de cuenta](/docs/explanation/account-models)