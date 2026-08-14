%{
  title: "Reintentar la configuración del proyecto",
  summary: "Recupere un proyecto después de que la configuración informe de un error.",
  category: "how-to",
  order: 4
}
---
Use **Reintentar configuración** después de corregir la condición que provocó el fallo de configuración de un proyecto.

## 1. Consulte el fallo

Abra la vista general del proyecto. La tarjeta de progreso de la configuración muestra el fallo y la actividad de configuración más reciente.

Las causas habituales incluyen:

- La cuenta no tiene ningún modelo configurado.
- Falta la clave del proveedor o ya no es válida.
- La aplicación de Glossia para GitHub no puede acceder al repositorio.
- No se pudo preparar o comprobar el repositorio.

## 2. Corrija el requisito previo

Para problemas con el modelo, abra **Configuración** y **Modelos**. Para problemas de acceso al repositorio, actualice la instalación de la aplicación de Glossia para GitHub en GitHub y concédale acceso al repositorio.

## 3. Vuelva a intentarlo

Regrese a la vista general del proyecto y seleccione **Reintentar configuración**.

La tarjeta vuelve a **Pendiente**, después pasa a **En curso** y muestra nueva actividad a medida que avanza el trabajo. La opción de reintentar solo está disponible mientras el proyecto se encuentra en estado **Fallido**, lo que impide que se ejecuten dos intentos de configuración al mismo tiempo.

## 4. Revise la finalización

Cuando el estado cambie a **Completado**, revise la solicitud de incorporación de cambios resultante en GitHub. Si vuelve a fallar, utilice la nueva actividad de la tarjeta, en lugar de la del intento anterior, para identificar la siguiente acción.