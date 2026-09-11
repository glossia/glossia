%{
  title: "Modelos de cuenta",
  summary:
    "¿Por qué los proveedores de modelos se configuran una vez por cuenta y son referenciados por manejador.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelo. Los repositorios describen qué se debe traducir, mientras que las cuentas deciden cuál [gran modelo de lenguaje](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo suele traducir varios repositorios con la misma relación con el proveedor. Los modelos asociados a la cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Esta separación también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible tal como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan una intención estable

El `model` campo en `L10N.md` hace referencia a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho manejador mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un conjunto, una cadena de respaldo ni un nivel de calidad automático. El autor del repositorio elige su propósito a través de identificadores estables como `translation-default`El documento reconstruido anteriormente falló la validación: la recuperación del nodo de texto de Markdown generó una traducción vacía `long-form`El documento reensamblado previamente falló la validación: la recuperación de texto literal de Markdown debe devolver un array de cadenas JSON de longitud coincidente `japanese-specialist`.

La selección sigue la jerarquía de contexto del documento y del idioma objetivo:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para ese idioma.
2. En otro caso, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` los ajustes se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia utiliza el predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia informa un error para un manejador desconocido en lugar de cambiar de forma silenciosa al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo añadido a una cuenta se convierte en el predeterminado, y un administrador puede establecer otro modelo como predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usando un identificador explícito deja clara su elección ante los revisores. Omitir `model` mantiene el repositorio en la configuración predeterminada de la cuenta.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para su revisión por el equipo. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.