%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma de destino a una configuración de Glossia existente.",
  category: "Guías",
  order: 1
}
---
Si ya tiene Glossia configurado y desea agregar otro idioma de destino, siga estos pasos.

## 1\. Actualice L10N.md

Abra su `L10N.md` y agregue el nuevo código de idioma al `targets` arreglo:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Agregue contexto específico del idioma (opcional)

Si el nuevo idioma requiere instrucciones especiales, como nivel de formalidad o consideraciones de conjunto de caracteres, cree un archivo de sobrescritura de contexto:

    L10N/
      ja.md

Escriba cualquier orientación específica del idioma en ese archivo. Glossia fusiona esto con el contexto base para las traducciones al japonés.

## 3\. Publicar el cambio de configuración

Realiza un commit y empuja la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma objetivo y inicia una
sesión de traducción.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas
y el contexto efectivo no han cambiado.

## 4\. Revisar la solicitud de extracción de traducción

Sigue la sesión de traducción en Glossia y luego revisa el idioma generado
archivos en la solicitud de extracción abierta por el servidor.