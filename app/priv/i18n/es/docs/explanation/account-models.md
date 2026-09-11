%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian por handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor del modelo. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden cuál [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible, como `translation-default`, no la clave del proveedor.

## Los identificadores proporcionan una intención estable

El `model` campo en `L10N.md` se refiere a un identificador de modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador podrá posteriormente actualizar qué modelo de proveedor selecciona dicho identificador mientras la configuración del repositorio se mantenga estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un ensamble, una cadena de respaldo, o un nivel automático de calidad. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form`, o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el idioma de destino:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para ese idioma.
2. De lo contrario, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` las configuraciones se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manage, Glossia usa el predeterminado de la cuenta.

Un manage configurado explícitamente debe existir. Glossia reporta un error para un manage desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

El setup de proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Glossia selecciona por lo tanto el predeterminado de la cuenta. El primer modelo agregado a una cuenta se convierte en el predeterminado, y un administrador puede hacer otro modelo el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`Al usar un identificador explícito, su elección queda clara para los revisores. Omitir `model` mantiene el repositorio en los valores predeterminados de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para revisión del equipo. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.