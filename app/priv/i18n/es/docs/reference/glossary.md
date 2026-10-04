%{
  title: "Glosario",
  summary:
    "Referencia para el campo de glosario en L10N.md y en el archivo de sobrescritura de cada idioma.",
  category: "referencia",
  section: "translation",
  order: 2
}
---
Un glosario del repositorio se divide en dos archivos. Glossia lo combina con el glosario de la cuenta para cada archivo que traduce. Consulte [Glosario](/docs/explanation/glossary) para cómo se combinan.

| Archivo | `glossary` contiene | Ejemplo |
|---|---|---|
| `L10N.md` | Una lista de **Términos**, las mismas para cada idioma. | `- source: commit` |
| `L10N/<locale>.md` | un mapa desde un término a su **traducción** en ese idioma. | `commit: commit` |

## Términos en L10N.md

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|---|
| `source` | string | sí | El término tal como aparece en el texto fuente. |
| `definition` | string | no | Breve guía que el modelo lee para decidir si una coincidencia es realmente este concepto. |
| `case_sensitive` | boolean | no | Cuando `true`, el término solo coincide exactamente tal como se escribe. Por defecto `false`. Úsalo para nombres y acrónimos tales como `API` o `SDK`. |
| `id` | string | no | Identificador estable. Derivado de `source` cuando se omite (`Version Control` se convierte `version-control`, `C++` se convierte `cplusplus`) Define las traducciones clave por id, para renombrar `source` sin perder la identidad del término, o para sobrescribir un término de un padre `L10N.md`. |

Los términos no contienen traducciones. Un término con un `targets` campo es rechazado: las traducciones pertenecen a los archivos de idioma.

## Traducciones en L10N/<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

Cada clave es del término `id` o la suya `source`, y cada valor es la traducción aprobada para ese idioma.

- Una clave que no coincide con ningún término en `L10N.md` declara un término solo para este idioma.
- Un término sin traducción en un idioma recurre al glosario de la cuenta de ese idioma.
- Para mantener un nombre sin traducir, mapearlo a sí mismo, por ejemplo `Glossia: Glossia`.

## Archivos anidados

Cada archivo se traduce con el glosario de su cadena de directorios:

- Un anidado `L10N.md` añade términos a los que hereda. Un término con el mismo `id`, o el mismo `source` cuando no `id` está configurada, reemplaza la heredada para ese subárbol.
- Un anidado `L10N/<locale>.md` añade traducciones a las que hereda, y su traducción prevalece para un término que ambos declaran.

## Validación

Si un glosario es inválido, Glossia traduce los archivos afectados con el glosario de la cuenta solo, por lo que un error tipográfico nunca bloquea las traducciones. Causas comunes:

- **Faltante `source`.** Cada término necesita un valor no vacío.
- **Duplicado `id`.** Cada término debe resolverse en un identificador único, ya sea establecido explícitamente o derivado de `source`.
- **Traducciones en L10N.md.** Un término con `targets`. Mueva las traducciones a `L10N/<locale>.md`.
- **Traducción vacía.** Un término mapeado a una cadena vacía. Omitíalo en su lugar.
- **Formatos o tipos incorrectos.** `glossary` debe ser una lista en `L10N.md` y un mapa en `L10N/<locale>.md`. Traducciones, `id`, y `definition` deben ser cadenas; `case_sensitive` debe ser `true` o `false`.

## Lo que registra Glossia

El archivo de bloqueo de cada archivo traducido registra las entradas del glosario que lo configuraron:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` enumera las entradas que coincidieron con el archivo. Las entradas de repositorio aparecen como `repo:<id>`, las entradas de cuenta como `account:<id>`.
- `shadowed` lista las entradas de cuenta que una entrada de repositorio reemplazó para este archivo.

Editar un término o una traducción solo vuelve a traducir los archivos que lo usan.

## Ver también

- [Definir un glosario](/docs/how-to/define-a-glossary): guía paso a paso.
- [Glosario](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y de la cuenta.
- [Referencia de L10N.md](/docs/reference/l10n-md)the other frontmatter fields.