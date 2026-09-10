%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "Guías",
  order: 1
}
---
Si ya tienes Glossia configurado y quieres añadir otro idioma de destino, sigue estos pasos.

## 1\. Actualizar L10N.md

Abre tu `L10N.md` y añade el nuevo código de idioma al `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Añadir contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o las consideraciones del conjunto de caracteres, cree un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escriba cualquier orientación específica del idioma en ese archivo. Glossia la fusiona con el contexto base para las traducciones al japonés.

## 3\. Publicar el cambio de configuración

Realice el commit y el push de la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Siga la sesión de traducción en Glossia, luego revise el idioma generado
archivos en la solicitud de extracción abierta por el servidor.