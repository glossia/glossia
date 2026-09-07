%{
  title: "Configurar un proveedor de modelos",
  summary: "Agregar un modelo de cuenta y referenciarlo de forma segura desde los repositorios.",
  category: "paso a paso",
  order: 3
}
---
Configuración de proyectos y las ejecuciones de traducción utilizan modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Agregar un modelo

1. Abra **Configuración** y seleccione **Modelos**.
2. Seleccione **Nuevo modelo**.
3. Introduzca un identificador único, como `translation-default`.
4. Abra el selector de modelos y escriba parte de un proveedor o nombre de modelo para filtrar la lista.
5. Seleccione un modelo e introduzca su clave de proveedor.
6. Guarde el modelo.

El identificador es estable incluso cuando cambie posteriormente el modelo de proveedor que lo sustenta. El primer modelo agregado a una cuenta se convierte en su predeterminado.

## Referenciar el modelo desde un repositorio

Establezca `model` en el frontmatter relevante de `GLOSSIA.md`:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave de proveedor permanece en la configuración de la cuenta.

## Elegir qué modelo se utiliza por defecto

Cuando `GLOSSIA.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que debería convertirse en predeterminado y seleccione **Establecer como predeterminado**.

Para un comportamiento predecible entre varios modelos, haga referencia explícita a un identificador en `GLOSSIA.md`.

Puede colocar un identificador `model` diferente en un `GLOSSIA.md` anidado para un área de contenido específica, o en `GLOSSIA/<locale>.md` para un idioma objetivo. Glossia utiliza la configuración aplicable más cercana para cada documento y idioma. No divide automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No hay respaldo en otro modelo.

## Cambiar o rotar una clave de proveedor

Abra **Configuración**, seleccione **Modelos** y abra el identificador del modelo. Introduzca una nueva clave de proveedor y guarde. Dejar el campo de clave en blanco mantiene la clave actual.

Los repositorios que hacen referencia al identificador no necesitan cambios.