%{
  title: "Definir un glosario",
  summary:
    "Declarar términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Guía",
  section: "translation",
  order: 6
}
---

Su equipo ya tiene términos que deben traducirse de una manera específica: nombres de productos que permanecen en inglés, términos técnicos con una presentación preferente, palabras de marca que transmiten un tono específico. Declárelas en su repositorio y Glossia las aplica a cada traducción futura.

Un glosario reside en dos tipos de archivos que ya utiliza:

- `L10N.md` declara los **términos**: qué es la palabra y qué significa. Esto es lo mismo para cada idioma.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Los revisores de cada idioma se encargan de su propio archivo.

Si su cuenta también tiene un glosario en Glossia, los dos se combinan en el momento de la traducción. Consulte [Glosario](/docs/explanation/glossary) para las reglas y para [cuándo usar cada uno](/docs/explanation/glossary#when-to-use-which).

## 1. Declare los términos en L10N.md

Agregue una `glossary` lista al frontmatter de su `L10N.md` raíz:

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

Cada término necesita un `source`, la palabra tal como aparece en su texto. Un `definition` ayuda al modelo a decidir si una coincidencia es realmente el concepto que tiene en mente. `case_sensitive: true` hace que `API` coincida sin coincidir con "api" en el texto.

## 2. Tradúzcalos en el archivo de cada idioma

Cree o abra `L10N/<locale>.md` junto a su `L10N.md` y asignue cada término a su traducción aprobada:

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

Las claves son la `source` del término. Un idioma sin traducción para un término vuelve al glosario de la cuenta, o permite que el modelo elija.

## 3. Agregue un término que solo necesite un idioma

Un archivo de idioma puede traducir una palabra que `L10N.md` no declara. Luego la regla se aplica solo a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Asigne un término una ID estable

Cuando una misma palabra necesita un significado preciso, o desea renombrar el `source` de un término más tarde, asígnele un `id` e identifique sus traducciones por esa ID:

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

## 5. Refina el glosario para parte del repositorio

Un `L10N.md` anidado o `L10N/<locale>.md` hereda de sus directorios padres y puede agregar o sobrescribir entradas para su subárbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos españoles bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6. Compromete y empuja

Compromete el cambio y empuja. En la siguiente ejecución de traducción, Glossia re-traduce solo los archivos que usan los términos que usted agregó o cambió, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos mantienen sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y usa solo el glosario de la cuenta, así que revise las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parezca aplicarse.

## Ver también

- [Referencia del Glosario](/docs/reference/glossary): cada campo y regla de validación.
- [Glosario](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y de la cuenta.
- [Referencia L10N.md](/docs/reference/l10n-md): los otros campos del frontmatter.
