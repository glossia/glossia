%{
  title: "Configura un proveedor de modelos",
  summary: "Añade un modelo de cuenta y referencíalo de forma segura desde los repositorios.",
  category: "Guías",
  order: 3
}
---
La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos e introduce parte del nombre del proveedor o del modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guarda el modelo.

El identificador es estable incluso si más adelante cambias el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referenciar el modelo desde un repositorio

Configurar `model` en el correspondiente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elegir qué modelo se utiliza por defecto

Cuando `L10N.md` omite `model`Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería ser el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible en varios modelos, haga referencia explícita a un manejador en `L10N.md`.

Puede colocar un manejador diferente `model` manejador en uno anidado `L10N.md` para una área de contenido, o en `L10N/<locale>.md` para un idioma objetivo. Glossia utiliza la configuración más cercana aplicable para cada documento y idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave de proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abrir el identificador del modelo. Introduzca una nueva clave de proveedor y guarde. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambios.