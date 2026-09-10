%{
  title: "Reintentar configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración informe un error.",
  category: "Guías",
  order: 4
}
---
Usar **Reintentar configuración** después de corregir la condición que provocó que la configuración del proyecto fallara.

## 1\. Leer el fallo

Abra la vista general del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene ningún modelo configurado.
- La clave del proveedor está ausente o ya no es válida.
- La aplicación GitHub de Glossia no puede acceder al repositorio.
- No se pudo preparar ni verificar el repositorio.

## 2\. Corregir el prerrequisito.

Para problemas del modelo, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación GitHub de Glossia en GitHub y conceda acceso al repositorio.

## 3\. Reintentar

Volver a la vista general del proyecto y seleccionar **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **Ejecutándose**, y muestra nueva actividad a medida que avanza el trabajo. El reintento está disponible solo mientras el proyecto está en **Fallido** estado, lo que impide que dos intentos de configuración se ejecuten simultáneamente.

## 4\. Revisar la finalización

Cuando el estado cambia a **Completado**, revisa la solicitud de extracción resultante en GitHub. Si falla nuevamente, usa la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.