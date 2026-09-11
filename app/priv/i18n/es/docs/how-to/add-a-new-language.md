%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración existente de Glossia.",
  category: "tutoriales",
  order: 1
}
---
Si ya tienes Glossia configurado y deseas añadir otro idioma de destino, sigue estos pasos.

## 1\. Actualiza L10N.md

Abre tu `L10N.md` y añade el nuevo código de idioma al `targets` arreglo:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Añade contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o consideraciones del conjunto de caracteres, crea un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escribe cualquier orientación específica del idioma en ese archivo. Glossia lo combina con el contexto base para las traducciones en japonés.

## 3\. Publicar el cambio de configuración

Realiza el commit y empuja la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Sigue la sesión de traducción en Glossia y luego revisa la traducción generada
archivos en la solicitud de extracción abierta por el servidor.