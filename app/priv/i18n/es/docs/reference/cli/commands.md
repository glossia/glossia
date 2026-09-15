%{
  title: "Comandos",
  summary:
    "Referencia para todos los comandos de la línea de comandos de Glossia y sus banderas.",
  category: "referencia",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crea una plantilla `L10N.md` de configuración del repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción se ejecuta en el servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos. Cuando se realiza un commit,
Glossia planifica el trabajo desde `L10N.md` de cada archivo, traduce cada archivo con
el modelo configurado en tu cuenta, y abre una solicitud de extracción con resultados. 
Puedes ver cada archivo y los giros del modelo en vivo en la página de sesión de traducción.

El modelo se elige por documento: `L10N.md` `model:` se nombra a uno de 
los modelos de tu cuenta seleccionados, de lo contrario se usa el modelo predeterminado de tu cuenta.

La interfaz de línea de comandos intencionalmente no planifica, traduce, valida,
inspecta o elimina las traducciones generadas. Tampoco lee 
archivos de bloqueo de traducción del servidor.

## `glossia revisit`

Reservado para una revisión futura del idioma de origen. La interfaz de línea de comandos
de Rust actualmente devuelve un error 'no implementado' para este comando.

```bash
glossia revisit
```

## Banderas globales

| Banderas | Descripción |
|---|---|
 | `--path <PATH>` | Sobreescribir el directorio raíz del proyecto |
 | `--no-color` | Deshabilitar salida en color |