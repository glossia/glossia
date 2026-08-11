%{
  title: "Configurar un proveedor de modelos",
  summary: "Añada un modelo de cuenta y haga referencia a él de forma segura desde los repositorios.",
  category: "how-to",
  order: 3
}
---
La configuración del proyecto y las ejecuciones de traducción utilizan los modelos configurados para la cuenta actual de Glossia. Configure al menos un modelo antes de crear un proyecto.

## Añadir un modelo

1. Abra **Configuración** y seleccione **Modelos**.
2. Seleccione **Nuevo modelo**.
3. Introduzca un identificador único, como `translation-default`.
4. Abra el selector de modelos y escriba parte del nombre de un proveedor o modelo para filtrar la lista.
5. Seleccione un modelo e introduzca la clave de su proveedor.
6. Guarde el modelo.

El identificador permanece estable aunque posteriormente cambie el modelo del proveedor asociado. El primer modelo añadido a una cuenta se convierte en el predeterminado.

## Referenciar el modelo desde un repositorio

Establezca `model` en el encabezado `GLOSSIA.md` correspondiente:

```yaml
---
model: translation-default
---
```

El repositorio solo almacena el identificador. La clave del proveedor permanece en la configuración de la cuenta.

## Elegir el modelo predeterminado

Cuando `GLOSSIA.md` omite `model`, Glossia utiliza el modelo predeterminado de la cuenta. Para cambiarlo, abra el modelo que desee establecer como predeterminado y seleccione **Establecer como predeterminado**.

Para obtener un comportamiento predecible con varios modelos, referencie explícitamente un identificador en `GLOSSIA.md`.

Puede incluir un identificador `model` diferente en un `GLOSSIA.md` anidado para un área de contenido, o en `GLOSSIA/<locale>.md` para una configuración regional de destino. Glossia utiliza la configuración aplicable más cercana para cada documento y configuración regional. No distribuye automáticamente el trabajo entre los modelos configurados.

Si un identificador explícito no existe en la cuenta, la traducción se detiene con un error. No recurre a otro modelo.

## Cambiar o rotar una clave de proveedor

Abra **Configuración**, seleccione **Modelos** y abra el identificador del modelo. Introduzca una nueva clave de proveedor y guarde los cambios. Si deja el campo de la clave en blanco, se conserva la clave actual.

Los repositorios que referencian el identificador no necesitan ningún cambio.