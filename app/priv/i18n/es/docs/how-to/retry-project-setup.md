%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto tras un error en la configuración.",
  category: "Tutorial",
  section: "translation",
  order: 4
}
---

Cuando la configuración automática falla, Glossia descarta el proyecto provisional para que el repositorio pueda seleccionarse nuevamente. Puede aparecer un aviso de fallo en el flujo de configuración, pero el proyecto fallido y su historial de progreso no se conservan.

## 1. Leer el fallo

Lea la notificación de fallo antes de salir del flujo de configuración. Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor no aparece o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni verificar.

## 2. Corregir el prerrequisito

Para problemas de modelos, abra **Configuración → Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y otórguele acceso al repositorio.

## 3. Iniciar la configuración nuevamente

Abra **Proyectos → Nuevo proyecto**, seleccione el repositorio, elija **Configuración automática** y seleccione los idiomas objetivo nuevamente. Siga el nuevo intento de configuración hasta que se complete.

Si un proyecto fallido sigue siendo visible y ofrece **Reintentar configuración**, esa acción inicia otro intento. No confíe en que permanezca disponible: los proyectos provisionales fallidos se eliminan durante la limpieza.

## 4. Revisar la finalización

Cuando la configuración se completa, revise la solicitud de extracción resultante en GitHub. Consulte [Configuración del proyecto](/docs/reference/project-setup) para conocer el ciclo de vida y el comportamiento de limpieza.
