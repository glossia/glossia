%{
  title: "Empezar",
  summary: "Conectar un repositorio y preparar su primera configuración de localización.",
  category: "Tutoriales",
  order: 1
}
---
Este tutorial conecta un repositorio de GitHub con Glossia, selecciona sus primeros idiomas objetivo y prepara una línea base de localización para que su equipo la revise.

## Antes de comenzar

Necesita:

- Una cuenta de Glossia donde puedas administrar configuraciones y proyectos.
- Un repositorio de GitHub en el que puedas otorgar a la aplicación de GitHub de Glossia permisos de lectura y actualización.
- Una clave de proveedor para un soportado [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configura un modelo de cuenta

Abre **Configuración,**, luego **Modelos,**, y selecciona **Nuevo modelo,**.

1. Asigne un alias corto al modelo, por ejemplo `translation-default`.
2. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
3. Seleccione el modelo que desea que Glossia use.
4. Ingrese la clave del proveedor y guarde el modelo.

El alias corto permite a los repositorios referenciar este modelo de cuenta sin colocar las credenciales del proveedor en el control de versiones. Consulte [Configurar proveedor de modelos](/docs/how-to/configure-a-model-provider) para más detalles.

## 2\. Inicie un proyecto

Volver a **Proyectos** y seleccione **Nuevo proyecto**.

Si Glossia solicita acceso al repositorio, siga el enlace a GitHub y conceda a la aplicación GitHub de Glossia el acceso al repositorio. Después de volver a Glossia, reabra **Nuevo proyecto** si es necesario.

## 3\. Elige un repositorio

Selecciona el repositorio que deseas localizar. Glossia solo lista los repositorios disponibles a través de la instalación de la App de GitHub de la cuenta actual.

Continuar al paso de idioma.

## 4\. Elige idiomas objetivo

Selecciona uno o más idiomas que deben generarse a partir del contenido de origen del repositorio y luego inicia la configuración.

## 5\. Sigue el progreso de la configuración

Mantén la página de configuración abierta mientras Glossia prepara el proyecto. La tarjeta de progreso muestra el estado actual y la actividad reciente, incluida la preparación del repositorio, la inspección de archivos, cambios, verificaciones y finalización.

Puede dejar la página y volver a la vista general del proyecto sin perder el estado de configuración. Si la configuración falla, la misma tarjeta explica qué necesita atención y ofrece **Reintentar configuración**.

## 6\. Revisar el resultado

Cuando la configuración se completa, abra la vista general del proyecto y revise la solicitud de extracción creada para el repositorio. La línea base propuesta normalmente incluye:

- Una raíz `L10N.md` archivo con el idioma fuente, las rutas de origen y los idiomas objetivo.
- Los cambios más pequeños de aplicación o contenido necesarios para cargar los archivos localizados.
- Cualquier validación ligera que ya estuviera disponible en el repositorio.

Revisa y fusiona la solicitud de extracción a través de tu flujo normal de GitHub. Las futuras ejecuciones de traducción utilizan el fusionado `L10N.md` contexto.

La vista general del proyecto mantiene la solicitud de extracción de configuración visible hasta que se fusione. Si se cierra sin fusionarse, reábrala desde el enlace en el aviso de configuración.

## Próximos pasos

- [Añadir un nuevo idioma](/docs/how-to/add-a-new-language)
- [Comprende los estados de configuración del proyecto](/docs/reference/project-setup)
- [Aprende cómo funcionan los modelos de cuenta](/docs/explanation/account-models)