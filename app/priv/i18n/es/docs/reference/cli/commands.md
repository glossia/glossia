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

Crear un inicial `L10N.md` archivo de configuración en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción es del lado del servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos. Cuando se realiza un commit,
Glossia planifica el trabajo desde tus `L10N.md` archivos, traduce cada archivo con
tu modelo configurado en tu cuenta, y abre una solicitud de extracción con los resultados. Tu
puede observar cada archivo y los turnos del modelo en vivo en la página de la sesión de traducción.

El modelo se elige por documento: un `L10N.md` `model:` nombrada una de tus
gestores de modelo de tu cuenta lo eligen; de lo contrario, se utiliza el modelo por defecto de la cuenta.

La interfaz de línea de comandos deliberadamente no planifica, traduce, valida,
inspecciona, ni elimina las traducciones generadas. Tampoco lee los del servidor
archivos de bloqueo de traducción.

## `glossia revisit`

Reservado para un paso futuro de revisión del idioma de origen. La línea de comandos de Rust
interfaz actualmente devuelve un error de no implementación para este comando.

```bash
glossia revisit
```

## Opciones globales

| Opción | Descripción |
|---|---|
| `--path <PATH>` | Sobreescribir el directorio raíz del proyecto |
| `--no-color` | Desactivar salida coloreada |