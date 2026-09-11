%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "Tutoriales",
  order: 3
}
---
La configuración del proyecto y las sesiones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y selecciona **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, por ejemplo `translation-default`.
4. Abre el selector de modelos y escribe parte del nombre del proveedor o del modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guarda el modelo.

El identificador es estable incluso si cambias posteriormente el modelo del proveedor que lo respalda. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Establecer `model` en la relevante `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el handle. La clave del proveedor permanece en la configuración de la cuenta.

## Elegir qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abre el modelo que debe convertirse en el predeterminado y selecciona **Hacer predeterminado**.

Para un comportamiento predecible en varios modelos, referencia explícitamente un manejador en `L10N.md`.

Puedes colocar un diferente `model` manejador en un anidado `L10N.md` para una área de contenido, o en `L10N/<locale>.md` para una sola localización de destino. Glossia usa la configuración más aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si no existe un identificador explícito en la cuenta, la traducción se detiene con un error. No se retrocede a otro modelo.

## Cambiar o rotar una clave del proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abre el identificador del modelo. Introduce una nueva clave del proveedor y guarda. Dejar el campo de clave vacío mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambios.