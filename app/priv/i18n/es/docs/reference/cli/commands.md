%{
  title: "Comandos",
  summary: "Referencia de todos los comandos de línea de comando de Glossia y sus banderas.",
  category: "referencia",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crea un archivo`L10N.md` inicia de configuración en el repositorio actual.

```bash
glossia init
```

Suscita fallo si `L10N.md` ya existe.

## La traducción se ejecuta en el servidor

La traducción se ejecuta en el servidor Glossia, no en la interfaz de línea de comandos. Cuando se realiza un commit,
Glossia planifica el trabajo desde tus `L10N.md` archivos, traduce cada uno con
el modelo configurado de tu cuenta, e inicia una solicitud de extracción con los resultados. Tú
podrás ver cada archivo y los giros del modelo en vivo en la página de la sesión de traducción.

El modelo se selecciona por documento: un `L10N.md` `model:` que nombra uno de tus
modelos de cuenta lo seleccionan; de lo contrario se usa el modelo predeterminado de tu cuenta.

La interfaz de línea de comandos deliberadamente no planifica, traduce, valida,
inspecciona ni borra las traducciones generadas. Tampoco lee los 
archivos de bloqueo de traducción del servidor.

## `glossia revisit`

Reservado para una pasada futura de revisión del idioma fuente. La interfaz de línea de comandos Rust
actualmente devuelve un error de no implementado para este comando.

```bash
glossia revisit
```

## Opciones globales

| Flag | Descripción |
|---|---|
| `--path <PATH>` | Sustituir el directorio raíz del proyecto |
| `--no-color` | Desactivar salida con color |