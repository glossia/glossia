%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recuperar un proyecto tras un fallo en la configuración.",
  category: "Cómo",
  order: 4
}
---
Usa **Reintentar configuración** después de corregir la condición que provocó el fallo de la configuración del proyecto.

## 1\. Leer el fallo

Abre el resumen del proyecto. La tarjeta de progreso de configuración muestra el fallo y la actividad de configuración más reciente.

Las causas comunes incluyen:

- La cuenta no tiene un modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- El repositorio no pudo prepararse ni verificarse.

## 2\. Solucione el prerrequisito

Para problemas de modelo, abra **Ajustes** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y otórquele acceso al repositorio.

## 3\. Reintentar

Volver al resumen del proyecto y seleccionar **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego **En ejecución**, y muestra nueva actividad a medida que avanza el trabajo. El reintento solo está disponible mientras el proyecto se encuentra en **Fallido** estado, lo que evita que dos intentos de configuración se ejecuten al mismo tiempo.

## 4\. Revisión de la finalización

Cuando el estado cambia a **Completado**, revisa la solicitud de extracción resultante en GitHub. Si falla de nuevo, utiliza la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.