%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "tutoriales",
  order: 3
}
---
La configuración del proyecto y las ejecuciones de traducción usan los modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduzca un identificador único, como `translation-default`.
4. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave de proveedor.
6. Guardar el modelo.

El identificador es estable incluso si más adelante cambia el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Establecer `model` en el correspondiente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor permanece en la configuración de cuenta.

## Selecciona el modelo que se utiliza por defecto

Cuando `L10N.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que se convierta en el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible en varios modelos, especifique un identificador explícitamente en `L10N.md`.

Puede colocar un identificador diferente `model` identificador en un entorno anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` Para un único idioma objetivo. Glossia utiliza la configuración más adecuada para cada documento e idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si no existe un manejador explícito en la cuenta, la traducción finaliza con un error. No recurre a otro modelo.

## Cambiar o rotar una clave del proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abre el manejador del modelo. Introduce una nueva clave del proveedor y guarda. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambiar.