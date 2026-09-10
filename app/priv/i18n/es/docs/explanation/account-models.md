%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante identificador.",
  category: "Explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor del modelo. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación de proveedor. Los modelos con alcance de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible como `translation-default`, no la clave del proveedor.

## Los identificadores aportan una intención estable

El campo `model` en `L10N.md` hace referencia a un identificador de modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo del proveedor selecciona ese identificador mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un ensamble, una cadena de respaldo ni un nivel de calidad automático. El autor del repositorio elige su propósito a través de identificadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el locale objetivo:

1. El archivo `L10N/<locale>.md` más cercano que declare `model` gana para ese locale.
2. De lo contrario, el archivo `L10N.md` más cercano que declare `model` gana para su directorio.
3. La configuración de los archivos `L10N.md` padre se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un identificador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un identificador configurado explícitamente. Glossia reporta un error para un identificador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Glossia elige, por tanto, el predeterminado de la cuenta. El primer modelo añadido a una cuenta se convierte en el predeterminado, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usar un identificador explícito hace que su elección sea clara para los revisores. Omitir `model` mantiene al repositorio en el predeterminado de la cuenta.

## El límite de la revisión humana

La salida del modelo es un trabajo propuesto, no una fusión automática. La configuración y la actividad de traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.