%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus opciones.",
  category: "Referencia",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crear un starter `L10N.md` archivo de configuración en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción es de lado del servidor

La traducción se ejecuta en el servicio alojado de Glossia, no en la interfaz de línea de comandos. Cuando ateriza un commit,
Glossia programa el trabajo a partir de tus `L10N.md` archivos, traduce cada archivo con
El modelo configurado de su cuenta y abre una solicitud de extracción con los resultados. Tú
puede ver cada archivo y los turnos del modelo en tiempo real en la página de sesión de traducción.

El modelo se selecciona por documento: un `L10N.md` `model:` nombrando uno de sus
gestor de modelos de su cuenta lo selecciona; de lo contrario, se usa el modelo predeterminado de su cuenta.

La interfaz de línea de comandos intencionalmente no planea, traduce, valida,
inspecciona, o elimina las traducciones generadas. Tampoco lee los archivos de bloqueo de traducción publicados por Glossia.

## `glossia revisit`

Reservado para un paso de revisión de idioma de origen en el futuro. La línea de comandos de Rust
La interfaz actualmente devuelve un error no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Bandera | Descripción |
|---|---|
| `--path <PATH>` | Sobrescribir el directorio raíz del proyecto |
| `--no-color` | Deshabilitar la salida coloreada |