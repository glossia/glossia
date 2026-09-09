%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus banderas.",
  category: "Referencia",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crea una plantilla`L10N.md` archivo de configuración en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción es lado del servidor

La traducción se ejecuta en el servidor Glossia, no en la interfaz de línea de comandos. Cuando aterrizan los cambios,
Glossia planifica el trabajo a partir de tus `L10N.md` archivos, traduce cada archivo con
el modelo configurado en tu cuenta y abre una pull request con los resultados. Tú
podrás atender cada archivo y los giros del modelo en vivo en la página de la sesión de traducción.

El modelo se elige por documento: un `L10N.md` `model:` que name uno de
los modelos de cuenta disponibles lo selecciona; de lo contrario, se usa el modelo por defecto de tu cuenta.

La interfaz de línea de comandos intencionalmente no planifica, traduce, valida,
inspecta, ni elimina las traducciones generadas. Tampoco lee los 
archivos de bloqueo de traducción del servidor.

## `glossia revisit`

Reservado para una revisión posterior del idioma fuente. La interfaz de línea de comandos 
de Rust devuelve actualmente un error no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Banderas | Descripción |
|---|---|
| `--path <PATH>` | Reemplazar el directorio raíz del proyecto |
| `--no-color` | Desactivar salida coloreada |