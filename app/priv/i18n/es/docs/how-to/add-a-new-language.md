%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "guías",
  section: "translation",
  order: 1
}
---

Si ya tienes Glossia configurada y deseas agregar otro idioma destino, sigue estos pasos.

## 1. Actualizar L10N.md

Abre tu `L10N.md` y agrega el nuevo código de idioma al array `targets`:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Añadir contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o consideraciones de conjunto de caracteres, crea un archivo de sobrescritura de contexto:

```
L10N/
  ja.md
```

Escribe en ese archivo cualquier guía específica del idioma. Glossia la combina con el contexto base para las traducciones al japonés.

## 3. Publicar el cambio de configuración

Realiza el commit y push la configuración actualizada. Si el repositorio está conectado a Glossia, el servidor detecta el nuevo idioma destino e inicia una sesion de traduccion.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas y el contexto efectivo no han cambiado.

## 4. Revisar la solicitud de extracción de traducción

Sigue la sesion de traduccion en Glossia y luego revisa los archivos de idioma generados en la solicitud de extracción abierta por el servidor.
