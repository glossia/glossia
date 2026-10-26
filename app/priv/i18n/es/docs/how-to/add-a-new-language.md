%{
  title: "Añadir un nuevo idioma",
  summary: "Cómo añadir un idioma objetivo a una configuración de Glossia existente.",
  category: "Guía",
  section: "translation",
  order: 1
}
---

Si ya tienes Glossia configurado y deseas agregar otro idioma de destino, sigue estos pasos.

## 1. Actualiza L10N.md

Abre tu `L10N.md` y añade el código del nuevo idioma al `targets` lista:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Agrega contexto específico para el idioma (opcional)

Si el nuevo idioma necesita instrucciones especiales, como un nivel de formalidad o consideraciones del conjunto de caracteres, crea un archivo de sobrescritura de contexto:

```
L10N/
  ja.md
```

Escriba cualquier orientación específica para el idioma en ese archivo. Glossia lo combina con el contexto base para las traducciones al japonés.

## 3. Publica el cambio de configuración

Realiza el commit y el push. Si el repositorio está conectado a Glossia, el servidor detecta el nuevo idioma de destino e inicia una sesion de traduccion.

Las traducciones existentes para otros idiomas permanecen sin cambios cuando sus entradas y contexto efectivo no han cambiado.

## 4. Revisa la solicitud de integración de traducción

Sigue la sesion de traduccion en Glossia y luego revisa los archivos de idioma generados en la solicitud de integración abierta por el servidor.
