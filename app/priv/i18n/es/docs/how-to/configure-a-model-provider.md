%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "Guía",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y selecciona **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduzca un identificador único, como `translation-default`.
4. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave del proveedor.
6. Guardar el modelo.

El identificador es estable incluso si más tarde cambia el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Especifique el modelo desde un repositorio

Configura `model` en el relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elija qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abre el modelo que debe convertirse en el predeterminado y selecciona **Hacer predeterminado**.

Para un comportamiento predecible en varios modelos, referencia explícitamente un handle en `L10N.md`.

Puede colocar un diferente `model` handle en un anidado `L10N.md` para una área de contenido, o en `L10N/<locale>.md` para una única localización objetivo. Glossia utiliza la configuración más aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si no existe un identificador explícito en la cuenta, la traducción se detiene con un error. No recurre automáticamente a otro modelo.

## Cambiar o rotar la clave del proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abrir el identificador del modelo. Ingresa una nueva clave del proveedor y guarda. Dejar el campo de la clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambios.