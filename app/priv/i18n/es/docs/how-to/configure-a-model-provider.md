%{
  title: "Configura un proveedor de modelos",
  summary: "Añade un modelo de cuenta y referencialo de forma segura desde repositorios.",
  category: "guía",
  section: "traducción",
  order: 3
}
---
La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos e introduce parte del nombre del proveedor o del modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guarda el modelo.

El identificador es estable incluso si cambias posteriormente el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Haz referencia al modelo desde un repositorio

Configurar `model` en la relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Selecciona qué modelo se utiliza por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debe convertirse en el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible entre varios modelos, haga referencia explícita a un identificador en `L10N.md`.

Puede colocar un identificador diferente `model` identificador en un anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` para una localización de destino. Glossia utiliza la configuración más aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si un manejador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave de proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abre el manejador del modelo. Ingresa una nueva clave de proveedor y guarda. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambios.