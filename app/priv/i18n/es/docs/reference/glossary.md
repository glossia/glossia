%{
  title: "Glosario",
  summary:
    "Referencia para el campo de glosario en L10N.md y en el archivo de sobrescritura de cada idioma.",
  category: "referencia",
  section: "translation",
  order: 2
}
---

Un glosario de repositorio se divide en dos archivos. Glossia lo combina con el glosario de la cuenta para cada archivo que traduce. Consulte [Glosario](/docs/explanation/glossary) para saber cómo se combinan entre sí.

| Archivo | `glossary` contiene | Ejemplo |
|---|---|---|
| `L10N.md` | Una lista de **términos**, la misma para todo idioma. | `- source: commit` |
| `L10N/<locale>.md` | Un mapa del término a su **traducción** en ese idioma. | `commit: commit` |

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
| `source` | texto | Sí | El término según aparece en el texto de origen. |
| `definition` | texto | no | Orientación breve que lee el modelo para decidir si una coincidencia es realmente este concepto. |
| `case_sensitive` | booleano | no | Cuando `true`, el término solo coincide con la escritura exacta. Por defecto es `false`. Úselo para nombres y acrónimos como `API` o `SDK`. |
| `id` | texto | no | Identificador estable. Se deriva de `source` cuando se omite (`Version Control` se convierte en `version-control`, `C++` se convierte en `cplusplus`). Confíguélo para usar en traducciones clave por id, para renombrar `source` sin perder la identidad del término, o para sobrescribir un término de un archivo de repaso `L10N.md`. |

Los términos no llevan traducciones. Un término con el campo `targets` es rechazado: las traducciones pertenecen en los archivos de idioma.

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

Cada clave es el `id` de un término o su `source`, y cada valor es la traducción aprobada para ese idioma.

- Una clave que no coincide con ningún término en `L10N.md` declara un término exclusivo para este idioma.
- Un término sin traducción en un idioma cae por defecto al glosario de la cuenta para ese idioma.
- Para mantener un nombre sin traducir, mapearlo a sí mismo, por ejemplo `Glossia: Glossia`.

## Archivos anidados

Cada archivo se traduce con el glosario de su cadena de directorios:

- Un `L10N.md` anidado agrega términos a los que hereda. Un término con el mismo `id`, o el mismo `source` cuando no hay `id` establecido, reemplaza al heredado para ese subárbol.
- Un `L10N/<locale>.md` anidado agrega traducciones a las que hereda, y su traducción vence para un término que ambos declaran.

## Validación

Si un glosario es inválido, Glossia traduce los archivos afectados usando solo el glosario de la cuenta, por lo que un error de dedo nunca bloquea las traducciones. Causas comunes:

- **Falta `source`.** Cada término necesita uno no vacío.
- **Duplicado `id`.** Cada término debe resolverse en un identificador único, ya sea configurado explícitamente o derivado de `source`.
- **Traducciones en L10N.md.** Un término con `targets`. Mueva las traducciones a `L10N/<locale>.md`.
- **Traducción vacía.** Un término mapeado a una cadena vacía. Omita en su lugar.
- **Formatos o tipos incorrectos.** `glossary` debe ser una lista en `L10N.md` y un mapa en `L10N/<locale>.md`. Las traducciones, `id`, y `definition` deben ser cadenas; `case_sensitive` debe ser `true` o `false`.

## Qué registra Glossia

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

- `applied` enumera las entradas que coincidieron con el archivo. Las entradas del repositorio aparecen como `repo:<id>`, las de la cuenta como `account:<id>`.
- `shadowed` enumera las entradas de la cuenta que una entrada del repositorio reemplazó para este archivo.

Editar un término o una traducción solo vuelve a traducir los archivos que lo usan.

## Véase también

- [Definir un glosario](/docs/how-to/define-a-glossary): guía paso a paso.
- [Glosario](/docs/explanation/glossary): cómo se combinan el glosario del repositorio y el de la cuenta.
- [Referencia L10N.md](/docs/reference/l10n-md): los otros campos frontmatter.
