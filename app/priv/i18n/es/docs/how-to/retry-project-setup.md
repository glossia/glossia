%{
  title: "Reintentar configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración reporte un error.",
  category: "Guía",
  order: 4
}
---
Utilice **Reintentar la configuración** después de corregir la condición que provocó el fallo en la configuración del proyecto.

## 1\. Lea el fallo

Abra el resumen del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor está ausente o ya no es válida.
- La aplicación GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni comprobar.

## 2\. Corrige el requisito previo

Para problemas del modelo, abre **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualiza la instalación de la aplicación GitHub de Glossia en GitHub y concede acceso al repositorio.

## 3\. Reintentar

Volver a la vista general del proyecto y seleccionar **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **En ejecución**, y muestra nueva actividad a medida que el trabajo avanza. El reintento solo está disponible mientras el proyecto se encuentra en **Fallido** estado, lo que impide que dos intentos de configuración se ejecuten al mismo tiempo.

## 4\. Revisar finalización

Cuando el estado cambia a **Completado**, revisa la solicitud de extracción resultante en GitHub. Si falla nuevamente, utiliza la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.