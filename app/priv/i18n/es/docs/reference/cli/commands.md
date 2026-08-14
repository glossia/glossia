%{
  title: "Comandos",
  summary: "Referencia de todos los comandos de línea de comandos de Glossia y sus opciones.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Cree un archivo de configuración inicial `GLOSSIA.md` en el repositorio actual.

```bash
glossia init
```

Falla si `GLOSSIA.md` ya existe.

## La traducción se realiza en el servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos. Cuando se incorpora una confirmación, Glossia planifica el trabajo a partir de sus archivos `GLOSSIA.md`, traduce cada archivo con el modelo configurado para su cuenta y abre una solicitud de incorporación de cambios con los resultados. Puede seguir en directo cada archivo y los turnos del modelo en la página de la sesion de traduccion.

El modelo se elige por documento: un `GLOSSIA.md` `model:` que indique uno de los identificadores de modelo de su cuenta lo selecciona; de lo contrario, se utiliza el modelo predeterminado de su cuenta.

La interfaz de línea de comandos no planifica, traduce, valida, inspecciona ni elimina deliberadamente las traducciones generadas. Tampoco lee los archivos de bloqueo de traducción del servidor.

## `glossia revisit`

Reservado para una futura fase de revisión del idioma de origen. Actualmente, la interfaz de línea de comandos de Rust devuelve un error de funcionalidad no implementada para este comando.

```bash
glossia revisit
```

## Opciones globales

| Opción | Descripción |
|---|---|
| `--path <PATH>` | Sobrescribir el directorio raíz del proyecto |
| `--no-color` | Desactivar la salida con colores |