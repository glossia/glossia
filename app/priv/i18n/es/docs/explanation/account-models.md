%{
  title: "Modelos de cuenta",
  summary: "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante un identificador.",
  category: "explanation",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen qué debe traducirse, mientras que las cuentas determinan qué [modelo de lenguaje de gran tamaño](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo suele traducir varios repositorios con la misma relación con el proveedor. Los modelos asociados a la cuenta permiten que los administradores roten una clave del proveedor o cambien el modelo subyacente una sola vez, sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible como `translation-default`, no la clave del proveedor.

## Los identificadores proporcionan una intención estable

El campo `model` de `GLOSSIA.md` hace referencia al identificador de un modelo de la cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Posteriormente, un administrador puede actualizar qué modelo del proveedor selecciona ese identificador mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo configurado para cada traducción de documento. Añadir varios modelos no crea un conjunto de modelos, una cadena de respaldo ni un nivel de calidad automático. El autor del repositorio determina su propósito mediante identificadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto del documento y la configuración regional de destino:

1. El archivo `GLOSSIA/<locale>.md` más cercano que declare `model` tiene prioridad para esa configuración regional.
2. En caso contrario, el archivo `GLOSSIA.md` más cercano que declare `model` tiene prioridad para su directorio.
3. La configuración de `GLOSSIA.md` del directorio superior se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un identificador, Glossia utiliza el valor predeterminado de la cuenta.

Un identificador configurado explícitamente debe existir. Glossia informa de un error si el identificador es desconocido, en lugar de cambiar silenciosamente al valor predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que el repositorio tenga su propio `GLOSSIA.md`. Por tanto, Glossia selecciona el modelo predeterminado de la cuenta. El primer modelo añadido a una cuenta se convierte en el predeterminado, y un administrador puede establecer otro modelo como predeterminado desde su página de configuración.

Cuando un repositorio ya tiene `GLOSSIA.md`, utilizar un identificador explícito deja clara su elección para quienes revisen los cambios. Omitir `model` mantiene el repositorio en el modelo predeterminado de la cuenta.

## El límite de la revisión humana

El resultado del modelo es una propuesta de trabajo, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de incorporación de cambios para que el equipo los revise. Esto conserva el mismo límite de calidad y responsabilidad que los equipos ya aplican al código.