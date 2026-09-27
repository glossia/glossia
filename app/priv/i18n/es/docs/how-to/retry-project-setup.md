%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto después de que la configuración informe un error.",
  category: "tutoriales",
  section: "traducción",
  order: 4
}
---
Usar **Reintentar configuración** después de corregir la condición que provocó el fallo en la configuración del proyecto.

## 1\. Lee el fallo

Abre la vista general del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene un modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni verificar.

## 2\. Corregir el requisito previo

Para problemas de modelo, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación GitHub de Glossia en GitHub y conceda acceso al repositorio.

## 3\. Reintentar

Volver a la vista general del proyecto y seleccionar **Reintentar configuración**.

La tarjeta regresa a **Pendiente**, luego **En ejecución**, y muestra la nueva actividad a medida que el trabajo avanza. La reintentación solo está disponible mientras el proyecto esté en **Fallido** estado, lo que evita que dos intentos de configuración se ejecuten simultáneamente.

## 4\. Revisión de la finalización

Cuando el estado cambia a **Completado**, revisa la solicitud de extracción resultante en GitHub. Si falla de nuevo, utiliza la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.