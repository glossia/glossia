%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma de destino a una configuración de Glossia existente.",
  category: "tutorial",
  section: "translation",
  order: 1
}
---
Si ya tiene Glossia configurado y desea agregar otro idioma de destino, siga estos pasos.

## 1\. Actualice L10N.md

Abra su `L10N.md` y agregue el nuevo código de idioma a la `targets` arreglo:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Agregue contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o las consideraciones de conjunto de caracteres, cree un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escriba cualquier orientación específica del idioma en ese archivo. Glossia la fusiona con el contexto base para traducciones al japonés.

## 3\. Publicar el cambio de configuración

Commit y push la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma de destino y comienza una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Siga la sesión de traducción en Glossia y luego revise el idioma generado
archivos en la solicitud de extracción abierta por el servidor.