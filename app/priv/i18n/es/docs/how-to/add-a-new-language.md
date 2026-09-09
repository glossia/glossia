%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma de destino a una configuración existente de Glossia.",
  category: "Guías",
  order: 1
}
---
Si ya tiene Glossia configurado y desea añadir otro idioma de destino, siga estos pasos.

## 1\. Actualizar L10N.md

Abre tu `L10N.md` y añade el nuevo código de idioma al `targets` Arreglo:

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

Realiza el commit y el push de la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecerán sin cambios cuando sus entradas
y contexto efectivo no hayan cambiado.

## 4\. Revisar la solicitud de traducción

Sigue la sesión de traducción en Glossia y luego revisa el idioma generado
archivos en la solicitud de extracción abierta por el servidor.