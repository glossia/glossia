%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde repositorios.",
  category: "tutorial",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, por ejemplo, `translation-default`.
4. Abre el selector de modelos e introduce parte del nombre de un proveedor o modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guardar el modelo.

El identificador es estable incluso cuando posteriormente cambias el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Definir `model` en el relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el handle. La clave del proveedor permanece en la configuración de la cuenta.

## Elija qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo por defecto de la cuenta. Para cambiarlo, abra el modelo que deba convertirse en el predeterminado y seleccione **Establecer como predeterminado**.

Para un comportamiento predecible entre varios modelos, haga referencia explícita a un `L10N.md`.

Puede colocar un diferente `model` identificador en un nivel anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` para un único idioma objetivo. Glossia utiliza la configuración más aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si el manejador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave del proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abre el manejador del modelo. Introduce una nueva clave del proveedor y guarda. Dejar el campo de clave vacío mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambiar.