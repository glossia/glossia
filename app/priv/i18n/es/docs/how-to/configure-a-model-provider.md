%{
  title: "Configurar un proveedor de modelos",
  summary: "Añadir un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "Tutoriales",
  section: "translation",
  order: 3
}
---
La configuración del proyecto y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abrir **Configuración** y seleccionar **Modelos**.
2. Seleccionar **Nuevo modelo**.
3. Introduce un identificador único, como `translation-default`.
4. Abre el selector de modelos e introduce parte del nombre de un proveedor o modelo para filtrar la lista.
5. Selecciona un modelo e introduce su clave del proveedor.
6. Guarda el modelo.

El identificador es estable incluso cuando cambias más tarde el modelo del proveedor subyacente. El primer modelo añadido a una cuenta se convierte en su predeterminado.

## Referencia el modelo desde un repositorio

Establecer `model` en el pertinente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

El repositorio almacena solo el handle. La clave del proveedor permanece en la configuración de cuenta.

## Selecciona el modelo que se usa por defecto

Cuando `L10N.md` omite `model`, Glossia usa el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería ser el predeterminado y seleccione **Hacer predeterminado**.

Para un comportamiento predecible en varios modelos, haga referencia explícitamente a un manejador en `L10N.md`.

Puede colocar un manejador diferente en un `model` manejador en un anidado `L10N.md` para un área de contenido, o en `L10N/<locale>.md` para un único idioma objetivo. Glossia usa la configuración más aplicable para cada documento y idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si no existe un manejador explícito en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave del proveedor

Abrir **Configuración**, seleccionar **Modelos**, y abrir el manejador del modelo. Introduzca una nueva clave del proveedor y guarde. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al handle no necesitan cambiar.

## Añadir Jev para decisiones de calidad de traducción

1. Abrir **Configuración → Modelos → Nuevo modelo** y seleccionar **Decisión** como categoría.
2. Utilice un handle como `translation-quality`. Mantener `typesafe/jev-latest`, o introduce una versión de modelo Jev de TypeSafe fijada.
3. Introduce tu clave de proveedor TypeSafe. Deja la dirección base vacía para usar el endpoint de TypeSafe nativo; una dirección personalizada debe incluir su prefijo de versión, tal como `https://api.typesafe.ai/v1`.
4. Establece la puntuación mínima de calidad de 1 a 10, luego guarda. El primer modelo de decisión se convierte en el modelo de decisión por defecto y habilita la evaluación automáticamente.
5. Ejecutar traducción. Las dimensiones de calidad fallidas requieren corrección dentro del `retries` presupuesto configurado en tu repositorio.

Los modelos generativos y de decisión tienen valores predeterminados diferentes. Mantener los manejadores de modelo de traducción sin cambios. Los modelos de decisión no pueden seleccionarse mediante manejadores de traducción del repositorio ni por las reglas de enrutamiento de idioma. Eliminar todos los modelos de decisión para desactivar la evaluación.