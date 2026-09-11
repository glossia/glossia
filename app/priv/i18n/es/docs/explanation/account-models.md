%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor del modelo. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden cuál [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## ¿Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con el mismo proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Esta separación también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible, como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan una intención estable.

El `model` campo en `L10N.md` hace referencia a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede posteriormente actualizar qué modelo de proveedor selecciona dicho manejador mientras la configuración del repositorio se mantiene estable.

## Cómo se utilizan varios modelos

Glossia usa un modelo configurado para cada traducción de documento. Agregando varios modelos no crea un ensemble, una cadena de respaldo ni un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`El documento reensamblado anteriormente falló la validación: la recuperación del literal de texto Markdown debe retornar un array de cadenas JSON de longitud coincidente `long-form`, o `japanese-specialist`.

Selección sigue la jerarquía de contexto para el documento y la localización objetivo:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para esa localización.
2. De lo contrario, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` Las configuraciones se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que el repositorio tenga el suyo. `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo agregado a una cuenta se convierte en el predeterminado, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usando un manejo explícito hace clara su elección para los revisores. Omitir `model` mantiene el repositorio en el predeterminado de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.