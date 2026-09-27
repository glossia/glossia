%{
  title: "Definir un glosario",
  summary:
    "Declarar los términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Guía",
  section: "Traducción",
  order: 6
}
---
Tu equipo ya tiene términos que deben traducirse de una forma específica: nombres de producto que permanecen en inglés, términos técnicos con un renderizado preferido, palabras de marca que transmiten un tono específico. Decláralos en tu repositorio y Glossia los aplicará a todas las traducciones futuras.

Un glosario reside en dos tipos de archivos que ya utilizas:

- `L10N.md` declara los **términos**: qué es la palabra y qué significa. Esto es igual para todo idioma.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Cada idioma tiene sus propios revisores que gestionan su propio archivo.

Si tu cuenta también tiene un glosario en el servidor, los dos se fusionan en el momento de la traducción. Consulta el [Glosario](/docs/explanation/glossary) para las reglas y para [cuándo usar cada uno](/docs/explanation/glossary#when-to-use-which).

## 1\. Declara los términos en L10N.md

Añade una lista `glossary` al frontmatter de tu `L10N.md` raíz:

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

Cada término necesita una `source`, la palabra tal como aparece en tu texto. Una `definition` ayuda al modelo a decidir si una coincidencia es realmente el concepto que pretendes. `case_sensitive: true` hará que `API` coincida, sin coincidir con "api" en el texto.

## 2\. Tradúcelos en el archivo de cada idioma

Crea o abre `L10N/<locale>.md` junto a tu `L10N.md` y asigna cada término a su traducción aprobada:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

Las claves son la `source` del término. Un idioma sin traducción para un término recurrirá al glosario del servidor o dejará que el modelo elija.

## 3\. Añade un término que solo necesite un idioma

Un archivo de idioma puede traducir una palabra que no declara `L10N.md`. La regla entonces se aplicará solo a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Proporciona un id estable a un término

Cuando la misma palabra necesita un significado preciso, o deseas renombrar la `source` de un término más tarde, dale un `id` y clave sus traducciones por ese id:

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## 5\. Refina el glosario para una parte del repositorio

Un `L10N.md` o `L10N/<locale>.md` anidado hereda de sus directorios padres y puede añadir o sobrescribir entradas para su subárbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos en español bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6\. Haz el commit y push

Haz el commit de la modificación y hazlo público. En la siguiente ejecución de traducción, Glossia retraduce solo los archivos que utilizan los términos que añadiste o cambiaste, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos conservan sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y usa solo el glosario del servidor, así que comprueba las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parece aplicarse.

## Ver también

- [Referencia del Glosario](/docs/reference/glossary): todos los campos y reglas de validación.
- [Glosario](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y del servidor.
- [Referencia de L10N.md](/docs/reference/l10n-md): los otros campos del frontmatter.