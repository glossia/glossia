%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian por handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen lo que debe ser traducido, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con un proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar todos los repositorios.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible, como `translation-default`, y no la clave del proveedor.

## Los manejadores proporcionan intención estable

El campo `model` en `L10N.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo del proveedor elige ese manejador mientras la configuración del repositorio se mantiene estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documentos. Agregar varios modelos no crea un ensamble, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía del contexto para el documento y la localización objetivo:

1. El archivo `L10N/<locale>.md` más cercano que declare `model` prevalece para esa localización.
2. En otro caso, el archivo `L10N.md` más cercano que declare `model` prevalece para su directorio.
3. La configuración del `L10N.md` padre se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declare un manejador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo agregado a una cuenta se convierte en el predeterminado, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usar un manejador explícito hace que su elección sea clara para los revisores. Omitir `model` mantiene el repositorio en el predeterminado de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción se mantiene visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.