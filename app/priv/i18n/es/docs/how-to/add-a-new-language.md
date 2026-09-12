%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "Guía",
  order: 1
}
---
Si ya tienes Glossia configurado y quieres agregar otro idioma de destino, sigue estos pasos.

## 1\. Actualiza L10N.md

Abre tu `L10N.md` y agrega el código del nuevo idioma al `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Agrega contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como nivel de formalidad o consideraciones del conjunto de caracteres, crea un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escribe cualquier orientación específica del idioma en ese archivo. Glossia lo combina con el contexto base para las traducciones al japonés.

## 3\. Publicar el cambio de configuración

Comite y ejecute la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios si sus entradas
y contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Siga la sesión de traducción en Glossia y luego revise el idioma generado
archivos en la solicitud de extracción abierta por el servidor.