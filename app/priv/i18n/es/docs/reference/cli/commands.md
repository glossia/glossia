%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus opciones.",
  category: "referencia",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crea un inicializador `L10N.md` un archivo de configuración en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción es del lado del servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos. Cuando se incorpora un commit,
Glossia planifica el trabajo desde sus `L10N.md` archivos, traduce cada archivo con
el modelo configurado de tu cuenta, y abre un pull request con los resultados. Tú
puedes ver cada archivo y los turnos del modelo en vivo en la página de sesión de traducción.

El modelo se elige por documento: un `L10N.md` `model:` nombrando uno de tus
manejos del modelo de tu cuenta lo seleccionan; de lo contrario, se utiliza el modelo predeterminado de tu cuenta.

La interfaz de línea de comandos intencionalmente no planifica, traduce, valida,
inspeccionar, ni eliminar las traducciones generadas. Tampoco lee del servidor.
archivos de bloqueo de traducción.

## `glossia revisit`

Reservado para una revisión futura del lenguaje de origen. La línea de comandos de Rust
interfaz actualmente devuelve un error no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Bandera | Descripción |
|---|---|
| `--path <PATH>` | Sobrescribir el directorio raíz del proyecto |
| `--no-color` | Desactivar salida coloreada |