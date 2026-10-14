%{
  title: "Reintentar configuracion del proyecto",
  summary: "Recuperar un proyecto despues de que la configuracion informe un error.",
  category: "guia",
  section: "translation",
  order: 4
}
---

Cuando la configuración automatizada falla, Glossia descarta el proyecto provisional para que el repositorio pueda ser seleccionado nuevamente. Podría aparecer un aviso de fallo en el flujo de configuración, pero el proyecto fallido y su historial de progreso no se conservan.

## 1. Lea el aviso de fallo

Lea el aviso de fallo antes de dejar el flujo de configuración. Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor está ausente o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- No se pudo preparar ni comprobar el repositorio.

## 2. Corregir el prerrequisito

Para problemas de modelo, abra **Configuración → Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y proporcione acceso al repositorio.

## 3. Iniciar la configuración de nuevo

Abra **Proyectos → Nuevo proyecto**, seleccione el repositorio, elija **Configuración automatizada** y seleccione los idiomas de destino nuevamente. Siga el nuevo intento de configuración hasta que se complete.

Si un proyecto fallido sigue siendo visible y ofrece **Reintentar configuración**, esa acción inicia otro intento. No confíe en que permanezca disponible: los proyectos provisionales fallidos se eliminan durante la limpieza.

## 4. Revisar la finalización

Cuando se complete la configuración, revise la solicitud de extracción resultante en GitHub. Consulte [Configuración del proyecto](/docs/reference/project-setup) para el ciclo de vida y el comportamiento de limpieza.
