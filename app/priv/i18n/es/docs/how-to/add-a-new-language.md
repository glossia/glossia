%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "cómo",
  section: "translation",
  order: 1
}
---

Si ya tienes Glossia configurada y deseas agregar otro lenguaje de destino, sigue estos pasos.

## 1. Actualizar L10N.md

Abre tu `L10N.md` y añade el nuevo código de idioma al array `targets`:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Agregar contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o consideraciones del conjunto de caracteres, crea un archivo de sobrescritura de contexto:

```
L10N/
  ja.md
```

Escribe cualquier guía específica del idioma en ese archivo. Glossia combina ello con el contexto base para las traducciones en japonés.

## 3. Publicar el cambio de configuración

Compromete y empuja la configuración actualizada. Si el repositorio se conecta a Glossia, el servidor detecta el nuevo lenguaje de destino y inicia una sesión de traducción.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas y el contexto efectivo no han cambiado.

## 4. Revisar la solicitud de extracción

Sigue la sesión de traducción en Glossia y luego revisa los archivos de idioma generados en la solicitud de extracción abierta por el servidor.
