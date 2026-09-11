%{
  title: "Agregar un nuevo idioma",
  summary: "Cómo agregar un idioma de destino a una configuración existente de Glossia.",
  category: "Guía",
  order: 1
}
---
Si ya tiene Glossia configurado y desea agregar otro idioma de destino, siga estos pasos.

## 1\. Actualice L10N.md

Abra su `L10N.md` y agregue el nuevo código de idioma a la `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Añadir contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o consideraciones del conjunto de caracteres, cree un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escriba cualquier orientación específica del idioma en ese archivo. Glossia lo fusiona con el contexto base para las traducciones en japonés.

## 3\. Publicar el cambio de configuración

Realice el commit y el push de la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo e inicia una traducción
sesión.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Siga la sesión de traducción en Glossia, luego revise el idioma generado
archivos en el pull request abierto por el servidor.