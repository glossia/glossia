%{
  title: "Glosario",
  summary:
    "Referencia para el campo de glosario en L10N.md y en el archivo de sobrescritura de cada idioma.",
  category: "referencia",
  section: "translation",
  order: 2
}
---

Un glosario de repositorio se divide en dos archivos. Glossia lo mezcla con el glosario de la cuenta para cada archivo que traduce. Consulta [Glosario](/docs/explanation/glossary) para ver cómo se combinan ambos.

| Archivo | `glossary` contiene | Ejemplo |
|---|---|---|
| `L10N.md` | Una lista de **términos**, la misma para cada idioma. | `- source: commit` |
| `L10N/<locale>.md` | Un mapeo desde el término hacia su **traducción** en ese idioma. | `commit: commit` |

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
| `source` | string | yes | El término tal como aparece en el texto original. |
| `definition` | string | no | Una guía breve que lee el modelo para decidir si una coincidencia es realmente este concepto. |
| `case_sensitive` | boolean | no | Cuando `true` el término solo coincide en la mayúscula exacta escrita. El valor predeterminado es `false`. Úsalo para nombres y acrónimos como `API` o `SDK`. |
| `id` | string | no | Identificador estable. Se deriva de `source` cuando se omite (`Version Control` pasa a `version-control`, `C++` pasa a `cplusplus`). Establece los identificadores clave por medio de la id, para renombrar `source` sin perder la identidad del término, o para sobrescribir un término de un padre `L10N.md`. |

Los términos no incluyen traducciones. Un término con un campo `targets` es rechazado: las traducciones pertenecen a los archivos del idioma.

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

Cada clave corresponde al `id` o al `source` de un término, y cada valor es la traducción aprobada para ese idioma.

- Una clave que no coincida con ningún término en `L10N.md` declara un término exclusivo para este idioma.
- Un término sin traducción en un idioma recurre al glosario de la cuenta para ese idioma.
- Para mantener un nombre sin traducir, mápelo a sí mismo, por ejemplo `Glossia: Glossia`.

## Archivos anidados

Cada archivo se traduce con el glosario de su cadena de directorios:

- Un `L10N.md` anidado agrega términos a los que hereda. Un término con la misma `id` o la misma `source` cuando no está configurada la `id` reemplaza el heredado para esa rama.
- Un `L10N/<locale>.md` anidado agrega traducciones a las que hereda, y su traducción gana para un término que ambos declaren.

## Validación

Si un glosario es inválido, Glossia traduce los archivos afectados solo con el glosario de la cuenta, para que un error tipográfico nunca bloquee las traducciones. Causas comunes:

- **Falta `source`.** Cada término necesita uno no vacío.
- **Duplicado de `id`.** Cada término debe resolverse en un identificador único, ya sea establecido explícitamente o derivado de `source`.
- **Traducciones en L10N.md.** Un término con `targets`. Mueve las traducciones a `L10N/<locale>.md`.
- **Traducción vacía.** Un término mapeado a una cadena vacía. Omítelo en su lugar.
- **Formas o tipos incorrectos.** `glossary` debe ser una lista en `L10N.md` y un mapa en `L10N/<locale>.md`. Las traducciones, `id` y `definition` deben ser strings; `case_sensitive` debe ser `true` o `false`.

## Qué registra Glossia

El archivo de bloqueo de cada archivo traducido registra las entradas de glosario que lo definieron:

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
- `shadowed` enumera las entradas de cuenta que una entrada de repositorio reemplazó para este archivo.

Editar un término o una traducción solo retraduce los archivos que lo utilizan.

## Véase también

- [Definir un glosario](/docs/how-to/define-a-glossary): guía paso a paso.
- [Glosario](/docs/explanation/glossary): cómo se combinan el glosario de repositorio y el de la cuenta.
- [Referencia de L10N.md](/docs/reference/l10n-md): los otros campos de frontmatter.
