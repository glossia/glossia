%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde los repositorios",
  category: "Guía",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan los modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduzca un identificador único, por ejemplo `translation-default`.
4. Abra el selector de modelos e introduzca parte del nombre de un proveedor o modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave de proveedor.
6. Guarde el modelo.

El identificador es estable incluso si posteriormente cambias el modelo del proveedor que hay detrás de él. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Configura `model` en el correspondiente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Selecciona qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que deba ser predeterminado y seleccione **Establecer como predeterminado**.

Para un comportamiento predecible en varios modelos, referencia explícitamente un identificador en `L10N.md`.

Puedes colocar un diferente `model` manejador en un anidado `L10N.md` para una área de contenido, o en `L10N/<locale>.md` para un único idioma de destino. Glossia utiliza la configuración más aplicable para cada documento e idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave del proveedor

Abrir **Configuración**, selecciona **Modelos**, y abre el identificador del modelo. Introduce una nueva clave del proveedor y guarda. Dejar el campo clave vacío mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambios.