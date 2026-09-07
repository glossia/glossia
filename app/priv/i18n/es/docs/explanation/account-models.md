%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante el handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen lo que debe traducirse, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos de alcance de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de código fuente. Un repositorio contiene un manejador legible como `translation-default`, y no la clave del proveedor.

## Los manejadores proporcionan intención estable

El campo `model` en `GLOSSIA.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo del proveedor selecciona ese manejador mientras la configuración del repositorio permanece estable.

## Cómo se usan varios modelos

Glossia usa un modelo configurado para cada traducción de documento. Agregar varios modelos no crea un conjunto, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el idioma local:

1. El archivo `GLOSSIA/<locale>.md` más cercano que declara `model` prevalece para esa localización.
2. De otro modo, el archivo `GLOSSIA.md` más cercano que declara `model` prevalece para su directorio.
3. Los ajustes del `GLOSSIA.md` padre se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia usa la predeterminación de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente a la predeterminación de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `GLOSSIA.md`. Por lo tanto, Glossia selecciona la predeterminación de la cuenta. El primer modelo agregado a una cuenta se convierte en el predeterminado, y un administrador puede establecer otro modelo como el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `GLOSSIA.md`, usar un manejador explícito hace que su elección sea clara para los revisores. Omite `model` mantiene el repositorio en la predeterminación de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.