%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus banderas.",
  category: "referencia",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crear un archivo `L10N.md` de configuración inicial en el repositorio actual.

```bash
glossia init
```

Falla si `L10N.md` ya existe.

## La traducción es del lado del servidor

La traducción se ejecuta en el servidor de Glossia, no en la interfaz de línea de comandos. Cuando se realiza un commit,
Glossia planifica el trabajo a partir de sus `L10N.md` archivos,, traduce cada archivo con
del modelo configurado de su cuenta, y abre un pull request con los resultados. Usted
puede ver cada archivo y los turnos del modelo en tiempo real en la página de la sesión de traducción.

El modelo se elige por documento: una `L10N.md` `model:` nomina uno de sus
modelo de cuenta lo selecciona; si no, se usa el modelo predeterminado de su cuenta.

La interfaz de línea de comandos intencionalmente no planifica, traduce, valida,
inspecciona, ni elimina las traducciones generadas. Tampoco lee los del servidor
archivos de bloqueo.

## `glossia revisit`

Reservado para una pasada futura de revisión del idioma fuente. La interfaz de línea de comandos
actualmente devuelve un error no implementado para este comando.

```bash
glossia revisit
```

## Opciones globales

| Opción | Descripción |
|---|---|
| `--path <PATH>` | Sobreescribir el directorio raíz del proyecto |
| `--no-color` | Deshabilitar salida de color |