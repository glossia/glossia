%{
  title: "Modelos de cuenta",
  summary: "Por qué los proveedores de modelos se configuran una vez por cuenta y se hacen referencia mediante manejador.",
  category: "explicación",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor del modelo. Los repositorios describen lo que debe ser traducido, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación de proveedor. Los modelos limitados por cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible, como `translation-default`, no la clave del proveedor.

## Los manejadores ofrecen una intención estable

El campo `model` en `GLOSSIA.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo del proveedor selecciona dicho manejador, mientras que la configuración del repositorio se mantiene estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un conjunto, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y la variante objetivo:

1. El archivo `GLOSSIA/<locale>.md` más cercano que declare `model` prevalece para esa variante.
2. De lo contrario, el archivo `GLOSSIA.md` más cercano que declare `model` prevalece para su directorio.
3. Los ajustes del `GLOSSIA.md` padre se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia utiliza la predeterminada de la cuenta.

Un manejador configurado explícitamente debe existir. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente a la predeterminada de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `GLOSSIA.md`. Glossia selecciona por lo tanto la predeterminada de la cuenta. El primer modelo añadido a una cuenta se convierte en el predeterminado, y un administrador puede establecer otro modelo como predeterminado en su página de configuración.

Una vez que un repositorio tiene `GLOSSIA.md`, usar un manejador explícito hace que su elección sea clara para los revisores. Omitir `model` mantiene al repositorio en la predeterminada de la cuenta.

## El límite de la revisión humana

La salida del modelo es un trabajo propuesto, no una fusión automática. La actividad de configuración y traducción se mantiene visible en Glossia, mientras que los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.