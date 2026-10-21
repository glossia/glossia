%{
  title: "Reintentar configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración informe un error.",
  category: "guía",
  section: "translation",
  order: 4
}
---

Cuando la configuración automatizada falla, Glossia descarta el proyecto provisional para que el repositorio pueda seleccionarse nuevamente. Puede aparecer un aviso de fallo en el flujo de configuración, pero el proyecto fallido y su historial de progreso no se conservan.

## 1. Lea el fallo

Lea el aviso de fallo antes de salir del flujo de configuración. Las causas comunes son:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor está faltante o ya no es válida.
- La aplicación Glossia GitHub no puede acceder al repositorio.
- No fue posible preparar ni comprobar el repositorio.

## 2. Corrija el requisito previo.

Para problemas de modelo, abra **Configuración → Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación Glossia GitHub en GitHub y conceda acceso al repositorio.

## 3. Inicie la configuración nuevamente

Abra **Proyectos → Nuevo proyecto**, seleccione el repositorio, elija **Configuración automatizada** y seleccione nuevamente los idiomas objetivo. Siga el nuevo intento de configuración hasta que se complete.

Si un proyecto fallido sigue visible y ofrece **Reintentar configuración**, esa acción inicia otro intento. No confíe en que siga disponible: los proyectos provisionales fallidos se eliminan durante la limpieza.

## 4. Revisar la finalización

Cuando la configuración se completa, revise la solicitud de extracción resultante en GitHub. Consulte [Configuración del proyecto](/docs/reference/project-setup) para el ciclo de vida y el comportamiento de limpieza.
