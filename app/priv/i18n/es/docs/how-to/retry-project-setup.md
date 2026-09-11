%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración reporte un fallo.",
  category: "tutorial",
  order: 4
}
---
Usar **Reintentar la configuración** después de corregir la condición que provocó el fallo de la configuración del proyecto.

## 1\. Lea el fallo

Abra el resumen del proyecto. La tarjeta de progreso de configuración muestra el fallo y la última actividad de configuración.

Las causas comunes incluyen:

- La cuenta no tiene un modelo configurado.
- La clave del proveedor está faltante o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- No se pudo preparar ni verificar el repositorio.

## 2\. Corrige el prerrequisito

Para problemas de modelo, abre **Ajustes** y **Modelos**. Para problemas de acceso al repositorio, actualiza la instalación de la aplicación de GitHub de Glossia en GitHub y bríndale acceso al repositorio.

## 3\. Reintentar

Volver al resumen del proyecto y seleccionar **Reintentar configuración**.

La tarjeta regresa a **Pendiente**, luego **En ejecución**, y muestra nueva actividad a medida que avanza el trabajo. Se puede reintentar solo mientras el proyecto esté en **Fallida** estado, lo que impide que dos intentos de configuración se ejecuten simultáneamente.

## 4\. Revisar finalización

Cuando el estado cambie a **Completado**, revise la solicitud de extracción resultante en GitHub. Si vuelve a fallar, utilice la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.