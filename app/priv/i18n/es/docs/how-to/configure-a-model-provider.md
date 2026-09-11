%{
  title: "Configura un proveedor de modelos",
  summary: "Añade un modelo de cuenta y haz referencia de forma segura desde los repositorios.",
  category: "Guías",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configura al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, por ejemplo `translation-default`.
4. Abre el selector de modelos y escribe parte del nombre de un proveedor o modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave del proveedor.
6. Guardar el modelo.

El identificador es estable incluso si cambias más tarde el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Establecer `model` en el pertinente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elige qué modelo se usa por defecto

Cuando `L10N.md` Omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que se convertirá en predeterminado y seleccione **Establecer como predeterminado**.

Para un comportamiento predecible en varios modelos, haga referencia explícita a un manejador en `L10N.md`.

Puedes colocar un diferente `model` manejador en un anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` para un único idioma de destino. Glossia utiliza la configuración más cercana aplicable para cada documento e idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si no existe un identificador explícito en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave de proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abre el identificador del modelo. Introduce una nueva clave de proveedor y guarda. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambios.