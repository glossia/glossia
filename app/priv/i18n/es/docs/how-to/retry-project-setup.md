%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración reporte un fallo.",
  category: "cómo hacerlo",
  order: 4
}
---
Usar **Reintentar configuración** después de corregir la condición que provocó el fallo en la configuración del proyecto.

## 1\. Leer el fallo

Abra la vista general del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- No fue posible preparar ni verificar el repositorio.

## 2\. Corregir el prerrequisito.

Para problemas del modelo, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualiza la instalación de la aplicación de GitHub de Glossia en GitHub y concede acceso al repositorio.

## 3\. Reintentar

Volver a la vista general del proyecto y seleccionar **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **Ejecutando**, y muestra nueva actividad a medida que avanza el trabajo. El reintento solo está disponible mientras el proyecto esté en **Fallido** estado, lo que impide que dos intentos de configuración se ejecuten al mismo tiempo.

## 4\. Revisión de finalización

Cuando el estado cambia a **Finalizado**, revisa la solicitud de extracción resultante en GitHub. Si falla de nuevo, usa la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.