%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma de destino a una configuración de Glossia existente.",
  category: "tutorial",
  section: "translation",
  order: 1
}
---
Si ya tienes Glossia configurado y deseas añadir otro idioma objetivo, sigue estos pasos.

## 1\. Actualiza L10N.md

Abre tu `L10N.md` y añade el código del nuevo idioma a la `targets` arreglo:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Añadir contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como nivel de formalidad o consideraciones del conjunto de caracteres, crea un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escribe cualquier orientación específica del idioma en ese archivo. Glossia la combina con el contexto base para las traducciones al japonés.

## 3\. Publicar el cambio de configuración

Realiza un commit y empuja la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de traducción

Sigue la sesión de traducción en Glossia, luego revisa el idioma generado
archivos en la solicitud de extracción abierta por el servidor.