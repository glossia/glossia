%{
  title: "Configura un proveedor de modelos",
  summary: "Añade un modelo de cuenta y haz referencia a él de forma segura desde repositorios.",
  category: "Guía",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configura al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Ajustes** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos e introduce parte del nombre del proveedor o del modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave del proveedor.
6. Guarda el modelo.

El identificador es estable incluso si más adelante cambias el modelo del proveedor que lo respalda. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referenciar el modelo desde un repositorio

Establecer `model` en el correspondiente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor se mantiene en la configuración de la cuenta.

## Elegir qué modelo se utiliza por defecto

Cuando `L10N.md` omite `model`\`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería convertirse en el predeterminado y seleccione **Establecer como predeterminado**.

Para un comportamiento predecible entre varios modelos, haga referencia explícitamente a un handle en `L10N.md`.

Puede colocar uno diferente `model` handle en un anidado `L10N.md` para una área de contenido, o en `L10N/<locale>.md` para una sola localización objetivo. Glossia utiliza la configuración más aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si un manejador explícito no existe en la cuenta, la traducción se detiene con un error. No regresa automáticamente a otro modelo.

## Cambiar o rotar una clave de proveedor

Abrir **Configuración**, seleccione **Modelos**, y abra el manejador del modelo. Introduzca una nueva clave de proveedor y guarde. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambiar.