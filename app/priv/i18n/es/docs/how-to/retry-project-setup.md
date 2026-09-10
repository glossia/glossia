%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración reporte un fallo.",
  category: "Guía paso a paso",
  order: 4
}
---
Usar **Reintentar configuración** después de corregir la condición que provocó el fallo en la configuración del proyecto.

## 1\. Leer el fallo

Abra el resumen del proyecto. La tarjeta de progreso de la configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluye:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni verificar.

## 2\. Soluciona el prerrequisito.

Para problemas de modelos, abre **Ajustes** y **Modelos**.

## 3\. Reintentar

Volver al resumen del proyecto y seleccionar **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **En ejecución**, y muestra nueva actividad a medida que avanza el trabajo. El reintento solo está disponible mientras el proyecto esté en **Fallida** , estado, lo que impide que dos sesiones de configuración se ejecuten simultáneamente.

## 4\. Revisar finalización

Cuando el estado cambia a **Completado**, revise la solicitud de extracción resultante en GitHub. Si falla de nuevo, utilice la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.