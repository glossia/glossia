%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante handle.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales de la identidad del proveedor de modelos. Los repositorios describen qué se debe traducir, mientras que las cuentas deciden cuál [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a cuentas

Un equipo a menudo traduce varios repositorios con la misma relación de proveedor. Los modelos con alcance de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de código fuente. Un repositorio contiene un manejador legible tal como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan intención estable

El `model` campo en `L10N.md` se refiere a un identificador del modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho identificador, mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia usa un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un ensamble, una cadena de respaldo, ni un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables tales como `translation-default`, `long-form`, o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el idioma objetivo:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para ese idioma.
2. De lo contrario, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` las configuraciones se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un identificador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un identificador configurado explícitamente. Glossia reporta un error para un identificador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga el suyo propio `L10N.md`. Glossia selecciona así el predeterminado de la cuenta. El primer modelo añadido a una cuenta se convierte en el predeterminado, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usando un identificador explícito hace que su elección sea clara para los revisores. Omitiendo `model` mantiene el repositorio en el predeterminado de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una integración automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para su revisión por el equipo. Esto conserva el mismo límite de propiedad y calidad que los equipos ya utilizan para el código.