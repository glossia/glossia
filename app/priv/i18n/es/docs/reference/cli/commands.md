%{
  title: "Comandos",
  summary: "Referencia para todos los comandos de línea de comandos de Glossia y sus banderas.",
  category: "referencia",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crea una plantilla`GLOSSIA.md` archivo de configuración en el repositorio actual.

```bash
glossia init
```

Falla si `GLOSSIA.md` ya existe.

## La traducción es de lado del servidor

La traducción se ejecuta en el servidor Glossia, no en la interfaz de línea de comandos. Cuando se realiza un commit,
Glossia planifica el trabajo desde tu `GLOSSIA.md` archivos, traduce cada archivo con
el modelo configurado de tu cuenta, y abre una solicitud de extracción con los resultados. Puedes
supervisar cada archivo y los turnos del modelo en vivo en la página de sesión de traducción.

El modelo se elige por documento: un`GLOSSIA.md` `model:` nombra uno de tus
modelo de cuenta maneja la selección; de lo contrario, se usa el modelo por defecto de tu cuenta.

La interfaz de línea de comandos no planea, traduce, valida,
inspecciona, ni elimina traducciones generadas. También no lee los
archivos de bloqueo de traducción.

## `glossia revisit`

Reservado para una pasada futura de revisión de idioma de origen. La interfaz de línea de comandos de Rust
actualmente devuelve un error de no implementado para este comando.

```bash
glossia revisit
```

## Banderas globales

| Banderas | Descripción |
|---|---|
|`--path <PATH>` | Anula el directorio raíz del proyecto |
|`--no-color` | Desactiva el Output Coloreado |