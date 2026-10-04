%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto tras un error en la configuración.",
  category: "Guías",
  section: "translation",
  order: 4
}
---
Cuando la configuración automática falla, Glossia descarta el proyecto provisional para que el repositorio pueda seleccionarse de nuevo. Podría aparecer un aviso de error en el flujo de configuración, pero el proyecto fallido y su historial de progreso no se conservan.

## 1\. Leer el error

Lee la notificación de error antes de abandonar el flujo de configuración. Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor está ausente o ya no es válida.
- La aplicación GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni verificar.

## 2\. Corregir el prerrequisito.

Para problemas del modelo, abra **Ajustes → Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y conceda acceso al repositorio.

## 3\. Inicie la configuración nuevamente

Abrir **Proyectos → Nuevo proyecto**, seleccione el repositorio, elija **Configuración automática**, y selecciona los idiomas objetivo de nuevo. Sigue el nuevo intento de configuración hasta que se complete.

Si un proyecto fallido sigue visible y ofrece **Reintentar configuración**, esa acción inicia otro intento. No confíes en que siga disponible: los proyectos provisionales fallidos se eliminan durante la limpieza.

## 4\. Revisar finalización

Cuando la configuración se completa, revisa la solicitud de extracción resultante en GitHub. Consulta [Configuración del proyecto](/docs/reference/project-setup) para el comportamiento del ciclo de vida y la limpieza.