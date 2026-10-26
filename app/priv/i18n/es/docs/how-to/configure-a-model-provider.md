%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde repositorios.",
  category: "tutorial",
  section: "translation",
  order: 3
}
---

La configuración de proyectos y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configura al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abre **Ajustes** y selecciona **Modelos**.
2. Selecciona **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos y escribe parte del nombre de un proveedor o modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave de proveedor.
6. Guarda el modelo.

El identificador es estable incluso cuando más adelante cambias el modelo del proveedor detrás de él. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Configura `model` en el frontmatter relevante de `L10N.md`:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elige qué modelo se usa por defecto

Cuando `L10N.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abre el modelo que debe convertirse en el predeterminado y selecciona **Configurar por defecto**.

Para un comportamiento predecible entre varios modelos, haz referencia explícita a un identificador en `L10N.md`.

Puedes colocar un identificador `model` diferente en uno anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` para un destino local. Glossia utiliza el ajuste aplicable más cercano para cada documento y local. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción termina con un error. No vuelve a otro modelo.

## Cambiar o rotar una clave de proveedor

Abre **Ajustes**, selecciona **Modelos** y abre el identificador del modelo. Introduce una nueva clave de proveedor y guarda. Dejar el campo de la clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambiar.

## Añade Jev para decisiones de calidad de traducción

1. Abre **Ajustes → Modelos → Nuevo modelo** y selecciona **Decisión** como categoría.
2. Usa un identificador como `translation-quality`. Guarda `typesafe/jev-latest`, o introduce una versión fija del modelo Jev de TypeSafe.
3. Introduce tu clave de proveedor de TypeSafe. Deja la dirección base vacía para usar el endpoint nativo de TypeSafe; una dirección personalizada debe incluir su prefijo de versión, como `https://api.typesafe.ai/v1`.
4. Establece la puntuación mínima de calidad de 1 a 10, luego guarda. El primer modelo de decisión se convierte en el modelo de decisión predeterminado y habilita la evaluación automáticamente.
5. Ejecuta la traducción. Las dimensiones de calidad fallidas solicitan corrección dentro del presupuesto `retries` configurado en tu repositorio.

Los modelos generativos y de decisión tienen predeterminados separados. Mantén tus identificadores de modelo de traducción sin cambios. Los modelos de decisión no se pueden seleccionar mediante los identificadores de traducción del repositorio ni las reglas de enrutamiento de local. Elimina todos los modelos de decisión para deshabilitar la evaluación.
