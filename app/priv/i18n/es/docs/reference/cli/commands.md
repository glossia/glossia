%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus opciones.",
  category: "Referencia",
  subcategory: "CLI",
  order: 1
}
---

## `glossia init`

Crea un archivo de configuración inicial `L10N.md` en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción se realiza en el servidor.

La traducción se ejecuta en el servicio alojado de Glossia, no en la interfaz de línea de comandos. Cuando un commit llega, Glossia planifica el trabajo a partir de tus archivos `L10N.md`, traduce cada archivo con el modelo configurado de tu cuenta y abre una solicitud de extracción con los resultados. Puedes observar cada archivo y los turnos del modelo en vivo en la página de sesión de traducción.

El modelo se elige por documento: un archivo `L10N.md` `model:` que nombra uno de los manejadores de modelo de tu cuenta lo selecciona; de lo contrario, se utiliza el modelo predeterminado de tu cuenta.

La interfaz de línea de comandos no planifica, traduce, valida, inspecciona ni elimina intencionalmente las traducciones generadas. Tampoco lee los archivos de bloqueo de traducción publicados por Glossia.

## `glossia revisit`

Reservado para una revisión futura del idioma de origen. La interfaz de línea de comandos de Rust actualmente devuelve un error de no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Bandera | Descripción |
|---|---|
| `--path <PATH>` | Sobrescribir el directorio raíz del proyecto |
| `--no-color` | Desactivar salida coloreada |
