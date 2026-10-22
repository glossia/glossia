%{
  title: "Configurar un proveedor de modelos",
  summary: "Agregar un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "Tutorial",
  section: "translation",
  order: 3
}
---

La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abra **Configuración** y seleccione **Modelos**.
2. Seleccione **Nuevo modelo**.
3. Introduzca un identificador único, tal como `translation-default`.
4. Abra el selector de modelos y escriba parte del nombre del proveedor o del modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave del proveedor.
6. Guarde el modelo.

El identificador permanece estable incluso si más adelante cambia el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencie el modelo desde un repositorio

Establezca `model` en el frontmatter correspondiente de `L10N.md`:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elija qué modelo se usa por defecto

Cuando `L10N.md` omita `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería convertirse en el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible entre varios modelos, refiérase explícitamente a un identificador en `L10N.md`.

Puede colocar un identificador `model` diferente en un `L10N.md` anidado para una área de contenido, o en `L10N/<locale>.md` para una localización objetivo. Glossia utiliza la configuración más próxima aplicable para cada documento y localización. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambie o rote una clave del proveedor

Abra **Configuración**, seleccione **Modelos** y abra el identificador del modelo. Introduzca una nueva clave del proveedor y guárdela. Dejar el campo de la clave vacío conserva la clave actual.

Los repositorios que hacen referencia al identificador no requieren cambios.

## Añada Jev para decisiones de calidad de traducción

1. Abra **Configuración → Modelos → Nuevo modelo** y seleccione **Decisión** como categoría.
2. Utilice un identificador tal como `translation-quality`. Conserve `typesafe/jev-latest`, o introduzca una versión fija del modelo Jev de TypeSafe.
3. Introduzca su clave del proveedor de TypeSafe. Deje la dirección base vacía para usar el extremo nativo de TypeSafe; una dirección personalizada debe incluir su prefijo de versión, tal como `https://api.typesafe.ai/v1`.
4. Establezca la puntuación de calidad mínima de 1 a 10, luego guarde. El primer modelo de decisión se convierte en el modelo de decisión predeterminado y habilita automáticamente la evaluación.
5. Ejecute la traducción. Las dimensiones de calidad fallidas solicitan corrección dentro del presupuesto de `retries` configurado en su repositorio.

Los modelos generativos y de decisión tienen predeterminados separados. Mantenga los identificadores de su modelo de traducción sin cambios. Los modelos de decisión no pueden ser seleccionados por los identificadores de traducción de repositorio o las reglas de enrutamiento de localización. Elimine todos los modelos de decisión para desactivar la evaluación.
