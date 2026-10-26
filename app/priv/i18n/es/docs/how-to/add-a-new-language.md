%{
  title: "Agregar un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "Tutorial",
  section: "translation",
  order: 1
}
---

Si ya tienes Glossia configurado y deseas agregar otro idioma de destino, sigue estos pasos.

## 1. Actualiza L10N.md

Abre tu `L10N.md` y añade el nuevo código de idioma al `targets` arreglo:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Agrega contexto específico del idioma (opcional)

Si el nuevo idioma requiere instrucciones especiales, como el nivel de formalidad o consideraciones sobre el conjunto de caracteres, crea un archivo de superposición del contexto:

```
L10N/
  ja.md
```

Escribe cualquier orientación específica del idioma en ese archivo. Glossia la fusiona con el contexto base para las traducciones al japonés.

## 3. Publica el cambio de configuración

Haz commit y push de la configuración actualizada. Si el repositorio está conectado a Glossia, el servidor detecta el nuevo idioma de destino e inicia una sesion de traduccion.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas y contexto efectivo no hayan cambiado.

## 4. Revisa la solicitud de extracción de traducción

Sigue la sesion de traduccion en Glossia, luego revisa los archivos de idioma generados en la solicitud de extracción abierta por el servidor.
