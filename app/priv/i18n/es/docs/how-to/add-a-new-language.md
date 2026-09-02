%{
  title: "Agregar un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración existente de Glossia.",
  category: "guía",
  order: 1
}
---
Si ya tiene Glossia configurado y desea añadir otro idioma de destino, siga estos pasos.

## 1\. Actualizar GLOSSIA.md

Abrir su `GLOSSIA.md` y añadir el código del nuevo idioma a la `targets` lista:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Añadir contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como nivel de formalidad o consideraciones del conjunto de caracteres, cree un archivo de sobrescritura de contexto:

    GLOSSIA/
      ja.md

Escriba cualquier orientación específica del idioma en ese archivo. Glossia lo combina con el contexto base para las traducciones al japonés.

## 3\. Publicar el cambio de configuración

Realizar commit y push la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma de destino y comienza una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Siga la sesión de traducción en Glossia, luego revise el idioma generado
archivos en la solicitud de extracción abierta por el servidor.