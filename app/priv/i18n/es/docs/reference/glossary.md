%{
  title: "Glosario",
  summary:
    "Referencia para el campo del glosario en L10N.md y en el archivo de sobrescritura de cada idioma.",
  category: "referencia",
  section: "traducción",
  order: 2
}
---
Un glosario de repositorio se divide en dos archivos. Glossia lo fusiona con el glosario del servidor de la cuenta para cada archivo que traduce. Vea [Glosario](/docs/explanation/glossary) para cómo se combinan ambos.

| Archivo | `glossary` contiene | Ejemplo |
|---|---|---|
| `L10N.md` | Una lista de **términos**, el mismo para cada idioma. | `- source: commit` |
| `L10N/<locale>.md` | Un mapa desde el término a su **traducción** en ese idioma. | `commit: commit` |

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

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source` | string | sí | El término tal como aparece en el texto original. |
| `definition` | string | no | Breve guía que el modelo lee para decidir si una coincidencia es realmente este concepto. |
| `case_sensitive` | boolean | no | Cuando `true`, el término solo coincide exactamente como se escribe. Por defecto `false`. Úselo para nombres y acrónimos como `API` o `SDK`. |
| `id` | string | no | Identificador estable. Derivado de `source` si se omite (`Version Control` se convierte `version-control`, `C++` se convierte `cplusplus`). Establezca las traducciones clave por id para renombrar `source` sin perder la identidad del término, o para sobrescribir un término de un padre `L10N.md`. |

Los términos no llevan traducciones. Un término con un `targets` campo es rechazado: las traducciones pertenecen a los archivos de idioma.

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

Cada clave es de un término `id` o de su `source`, y cada valor es la traducción aprobada para ese idioma.

- Una clave que no coincida con ningún término en `L10N.md` declara un término para este idioma únicamente.
- Un término sin traducción en un idioma recurre al glosario del servidor para ese idioma.
- Para mantener un nombre sin traducir, mápelo a sí mismo, por ejemplo `Glossia: Glossia`.

## Archivos anidados

Cada archivo se traduce con el glosario de su cadena de directorios:

- Un archivo anidado `L10N.md` añade términos a los que hereda. Un término con el mismo `id`, o el mismo `source` cuando no `id` está configurado, reemplaza la heredada de ese subárbol.
- Un anidado `L10N/<locale>.md` añade traducciones a las que hereda, y su traducción gana para un término que ambos declaran.

## Validación

Si un glosario es inválido, Glossia traduce los archivos afectados con el glosario del servidor solo, por lo que un error tipográfico nunca bloquea traducciones. Causas comunes:

- **Falta `source`,** Cada término necesita uno no vacío.
- **Duplicado `id`.** Cada término debe resolverse en un identificador único, ya sea establecido explícitamente o derivado de `source`.
- **Traducciones en L10N.md.** Un término con `targets`. Mueva las traducciones a `L10N/<locale>.md`.
- **Traducción vacía.** Un término mapeado a una cadena vacía. En su lugar, omita este término.
- **Estructuras o tipos incorrectos.** `glossary` Debe ser una lista en `L10N.md` y un mapa en `L10N/<locale>.md`. Traducciones, `id`, y `definition` deben ser cadenas; `case_sensitive` debe ser `true` o `false`.

## Lo que Glossia registra

El archivo de bloqueo de cada archivo traducido registra las entradas del glosario que lo formaron:

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

- `applied` lista las entradas que coincidieron con el archivo. Las entradas del repositorio aparecen como `repo:<id>`, las entradas del servidor como `account:<id>`.
- `shadowed` lista las entradas del servidor que una entrada del repositorio reemplazó para este archivo.

Editar un término o una traducción solo vuelve a traducir los archivos que lo usan.

## Véase también

- [Definir un glosario](/docs/how-to/define-a-glossary): guía paso a paso.
- [Glosario](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y del servidor.
- [referencia L10N.md](/docs/reference/l10n-md): los otros campos frontmatter.