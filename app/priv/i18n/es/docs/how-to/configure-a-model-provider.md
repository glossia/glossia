%{
  title: "Configurar un proveedor de modelo",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde repositorios.",
  category: "Cómo hacer",
  section: "translation",
  order: 3
}
---

La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abra **Ajustes** y seleccione **Modelos**.
2. Seleccione **Nuevo modelo**.
3. Introduzca un identificador único, como `translation-default`.
4. Abra el selector de modelos y escriba parte del nombre del proveedor o modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave del proveedor.
6. Guarde el modelo.

El identificador es estable incluso cuando cambie posteriormente el modelo del proveedor que está detrás. El primer modelo agregado a una cuenta se convierte en su valor por defecto.

## Referenciar el modelo desde un repositorio

Establezca `model` en la `L10N.md` cabecera de frontmatter relevante:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elegir qué modelo se utiliza por defecto

Cuando `L10N.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería convertirse en el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible entre varios modelos, haga referencia explícitamente a un identificador en `L10N.md`.

Puede colocar un identificador `model` diferente en una `L10N.md` anidada para un área de contenido, o en `L10N/<locale>.md` para un idioma objetivo. Glossia utiliza la configuración más cercana aplicable para cada documento y idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave del proveedor

Abra **Ajustes**, seleccione **Modelos** y abra el identificador del modelo. Introduzca una nueva clave del proveedor y guarde. Dejar en blanco el campo de la clave mantiene la clave actual.

Los repositorios que hace referencia al identificador no necesitan cambiar.

## Añadir Jev para decisiones de calidad de traducción

1. Abra **Ajustes → Modelos → Nuevo modelo** y seleccione **Decisión** como categoría.
2. Utilice un identificador como `translation-quality`. Mantenga `typesafe/jev-latest` o introduzca una versión fijada del modelo Jev TypeSafe.
3. Introduzca su clave de proveedor de TypeSafe. Deje la dirección base vacía para usar el endpoint nativo de TypeSafe; una dirección personalizada debe incluir su prefijo de versión, como `https://api.typesafe.ai/v1`.
4. Establezca la puntuación mínima de calidad de 1 a 10, luego guarde. El primer modelo de decisión se convierte en el modelo de decisión predeterminado y habilita la evaluación automáticamente.
5. Ejecute la traducción. Las dimensiones de calidad fallidas solicitan corrección dentro del `retries` presupuesto configurado en su repositorio.

Los modelos generativos y de decisión tienen predeterminados separados. Mantenga los identificadores de sus modelos de traducción sin cambios. Los modelos de decisión no pueden ser seleccionados por los identificadores de traducción del repositorio ni por las reglas de enrutamiento de idioma. Elimine todos los modelos de decisión para deshabilitar la evaluación.
