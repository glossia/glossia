%{
  title: "Define un glosario",
  summary:
    "Declara los términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Guía",
  section: "translation",
  order: 6
}
---
Tu equipo ya tiene términos que deben traducirse de forma específica: nombres de productos que quedan en inglés, términos técnicos con una representación preferida, palabras de marca que llevan un tono determinado. Decláralos en tu repositorio y Glossia los aplica a cada traducción futura.

Un glosario reside en dos tipos de archivos que ya usas:

- `L10N.md` declara los **términos**: qué es la palabra y qué significa. Esto es lo mismo para cada idioma.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Los revisores de cada idioma son responsables de su propio archivo.

Si tu cuenta también tiene un glosario en Glossia, ambos se combinan en tiempo de traducción. Vea [Glossary](/docs/explanation/glossary) para las reglas y para [cuándo usar cuál](/docs/explanation/glossary#when-to-use-which).

## 1\. Declara los términos en L10N.md

Añade una lista `glossary` al frontmatter de tu raíz `L10N.md`:

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

Cada término necesita un `source`, la palabra tal como aparece en tu texto. Una `definition` ayuda al modelo a decidir si una coincidencia es realmente el concepto que quieres. `case_sensitive: true` hace que `API` coincida sin coincidir con "api" en el texto.

## 2\. Trasladas en el archivo de cada idioma

Crea o abre `L10N/<locale>.md` al lado de tu `L10N.md` y mapea cada término a su traducción aprobada:

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

Las claves son el `source` del término. Un idioma sin traducción para un término recurre al glosario de la cuenta, o deja que el modelo eliga.

## 3\. Añade un término que solo un idioma necesita

Un archivo de idioma puede traducir una palabra que `L10N.md` no declara. La regla entonces se aplica solo a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Da un id estable a un término

Cuando la misma palabra necesita un significado preciso, o deseas cambiar el `source` de un término más tarde, dáselo un `id` y enclava sus traducciones por ese id:

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

Un `L10N.md` o `L10N/<locale>.md` anidado hereda de sus directorios padre y puede agregar o sobrescribir entradas para su árbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos en español bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6\. Compromete y empuja

Compromete el cambio y empuja. En la siguiente ejecución de traducción, Glossia re-traduce solo los archivos que usan los términos que añadiste o cambiaste, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos mantienen sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y usa solo el glosario de la cuenta, por lo tanto, comprueba las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parece aplicar.

## Ver también

- [Referencia de glosario](/docs/reference/glossary): cada campo y regla de validación.
- [Glossary](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y de la cuenta.
- [Referencia L10N.md](/docs/reference/l10n-md): los otros campos del frontmatter.