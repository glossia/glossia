%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración reporte un fallo.",
  category: "Guía",
  order: 4
}
---
Utilice **Reintentar configuración** después de corregir la condición que provocó que la configuración del proyecto fallara.

## 1\. Lea el fallo

Abra la vista general del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene un modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- El repositorio no pudo prepararse o verificarse.

## 2\. Corregir el prerrequisito

Para problemas de modelos, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y otorganle acceso al repositorio.

## 3\. Reintentar

Vuelva a la vista general del proyecto y seleccione **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **En ejecución**, y muestra nueva actividad a medida que avanza el trabajo. Reintentar está disponible solo mientras el proyecto se encuentra en estado **Fallido**, lo que impide que dos intentos de configuración se ejecuten al mismo tiempo.

## 4\. Revisar la finalización

Cuando el estado cambie a **Completado**, revise la solicitud de extracción resultante en GitHub. Si falla nuevamente, utilice la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.