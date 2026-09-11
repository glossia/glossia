%{
  title: "Comandos",
  summary: "Referencia de todos los comandos de línea de comandos de Glossia y sus opciones.",
  category: "Referencia",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Cree una plantilla`L10N.md`archivo de configuración L10N.md en el repositorio actual.

```bash
glossia init
```

Resulta en error si`L10N.md`L10N.md

## La traducción se realiza en el servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos.A cuando un commit se envía,
Glossia planea el trabajo a partir de sus`L10N.md`archivos L10N.md
y traduce cada archivo con el modelo configurado de su cuenta, y abre una solicitud de extracción con los resultados. Usted
puede observar cada archivo y los giros del modelo en vivo en la página de sesion de traduccion.

El modelo se elige por documento: un`L10N.md`modelo:`model:`naming one of your
account model handles selects it; otherwise your account's default model is used.

La interfaz de línea de comandos no planifica, traduce, valida,
inspecciona, ni elimina traducciones generadas. tampoco lee los
archivos de bloqueo de traducción del servidor.

## `glossia revisit`

Reservado para una revisión futura del idioma fuente. La interfaz de línea de comandos en Rust
 actualmente devuelve un error no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Flag | Descripción |
|---|---|
| `--path <PATH>` | Sobrescribir el directorio raíz del proyecto |
| `--no-color` | Desactivar salida coloreada |