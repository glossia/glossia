%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se hacen referencia mediante handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen lo que debe traducirse, mientras que las cuentas deciden cuál [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible como `translation-default`" , no es la clave del proveedor.

## Los identificadores proporcionan una intención estable.

El `model` campo en `L10N.md` se refiere a un identificador de modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho identificador, mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un conjunto, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de identificadores estables como `translation-default`, `long-form`, o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y la localización objetivo:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para esa localización.
2. De lo contrario, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` la configuración se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Glossia selecciona por lo tanto el predeterminado de la cuenta. El primer modelo agregado a una cuenta se convierte en el predeterminado, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usando un manejador explícito aclara su elección para los revisores. Omitiendo `model` Mantiene el repositorio en el predeterminado de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.