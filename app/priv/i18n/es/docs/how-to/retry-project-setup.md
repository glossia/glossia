%{
  title: "Reintentar configuración del proyecto",
  summary: "Recuperar un proyecto tras un fallo en la configuración.",
  category: "how-to",
  order: 4
}
---
Utilice **Reintentar configuración** después de solucionar la condición que provocó el fallo en la configuración del proyecto.

## 1\. Lea el fallo

Abra la vista general del proyecto. La tarjeta de progreso de configuración muestra el fallo y la última actividad de configuración.

Las causas comunes incluyen:

- La cuenta no tiene un modelo configurado.
- La clave del proveedor falta o ya no es válida.
- La aplicación de GitHub de Glossia no puede acceder al repositorio.
- El repositorio no se pudo preparar ni verificar.

## 2\. Solucione el requisito previo

Para problemas de modelo, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de GitHub de Glossia en GitHub y conceda acceso al repositorio.

## 3\. Reintentar

Vuelva a la vista general del proyecto y seleccione **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, luego a **En ejecución** y muestra una nueva actividad a medida que avanza el trabajo. Reintentar está disponible solo mientras el proyecto se encuentra en el estado **Fallido**, lo que evita que dos intentos de configuración se ejecuten simultáneamente.

## 4\. Revise la finalización

Cuando el estado cambie a **Completada**, revise la solicitud de extracción resultante en GitHub. Si falla nuevamente, utilice la nueva actividad en la tarjeta en lugar del intento anterior para identificar la siguiente acción.