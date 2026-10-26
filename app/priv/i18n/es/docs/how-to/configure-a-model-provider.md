%{
  title: "Configura un proveedor de modelos",
  summary: "Añade un modelo de cuenta y haz referencia de forma segura desde los repositorios.",
  category: "Guía",
  section: "translation",
  order: 3
}
---

La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abre **Configuración** y selecciona **Modelos**.
2. Selecciona **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos y escribe una parte del nombre del proveedor o del modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guarda el modelo.

El identificador es estable incluso cuando luego cambias el modelo de proveedor que subyace a él. El primer modelo agregado a una cuenta se convierte en su predeterminado.

## Referencia del modelo desde un repositorio

Define `model` en el frontmatter pertinente `L10N.md`:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave de proveedor permanece en la configuración de la cuenta.

## Elegir qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abre el modelo que debería convertirse en el predeterminado y selecciona **Hacer predeterminado**.

Para un comportamiento predecible entre varios modelos, referencia un identificador explícitamente en `L10N.md`.

Puedes colocar un identificador `model` diferente en un `L10N.md` anidado para un área de contenido, o en `L10N/<locale>.md` para un idioma objetivo. Glossia utiliza la configuración más cercana aplicable para cada documento y idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No retrocede a otro modelo.

## Cambiar o rotar una clave de proveedor

Abre **Configuración**, selecciona **Modelos** y abre el identificador del modelo. Introduce una nueva clave de proveedor y guarda. Dejar el campo de la clave vacío mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambiar.

## Agregar Jev para decisiones de calidad de traducción

1. Abre **Configuración → Modelos → Nuevo modelo** y selecciona **Decisión** como categoría.
2. Utiliza un identificador como `translation-quality`. Consérva `typesafe/jev-latest`, o introduce una versión anclada del modelo Jev de TypeSafe.
3. Introduce tu clave de proveedor de TypeSafe. Deja la dirección base vacía para usar el endpoint nativo de TypeSafe; una dirección personalizada debe incluir su prefijo de versión, como `https://api.typesafe.ai/v1`.
4. Establece la puntuación de calidad mínima de 1 a 10, luego guarda. El primer modelo de decisión se convierte en el modelo de decisión predeterminado y activa la evaluación automáticamente.
5. Ejecuta la traducción. Las dimensiones de calidad fallidas solicitan corrección dentro del presupuesto `retries` configurado en tu repositorio.

Los modelos generativos y de decisión tienen un predeterminado separado. Mantiene los identificadores de los modelos de traducción sin cambios. Los modelos de decisión no pueden ser seleccionados por los identificadores de traducción de repositorio o las reglas de enrutamiento de idioma. Elimina todos los modelos de decisión para desactivar la evaluación.
