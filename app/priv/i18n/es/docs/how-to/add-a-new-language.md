%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma de destino a una configuración existente de Glossia.",
  category: "how-to",
  order: 1
}
---
Si ya tiene Glossia configurado y quiere añadir otro idioma de destino, siga estos pasos.

## 1. Actualice GLOSSIA.md

Abra su `GLOSSIA.md` y añada el nuevo código de idioma al array `targets`:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Añada contexto específico del idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como el nivel de formalidad o consideraciones sobre el juego de caracteres, cree un archivo de configuración de contexto:

```
GLOSSIA/
  ja.md
```

Escriba en ese archivo las indicaciones específicas del idioma. Glossia las combina con el contexto base para las traducciones al japonés.

## 3. Publique el cambio de configuración

Confirme y envíe la configuración actualizada. Si el repositorio está conectado a
Glossia, el servidor detecta el nuevo idioma de destino e inicia una sesión de
traducción.

Las traducciones existentes en otros idiomas permanecen sin cambios cuando sus entradas
y su contexto efectivo no han cambiado.

## 4. Revise la solicitud de incorporación de cambios de traducción

Siga la sesión de traducción en Glossia y, después, revise los archivos generados para el idioma
en la solicitud de incorporación de cambios abierta por el servidor.