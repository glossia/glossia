%{
  title: "Definir un glosario",
  summary:
    "Declarar los términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Tutorial",
  section: "translation",
  order: 6
}
---

Tu equipo ya tiene términos que deben traducirse de una manera específica: nombres de productos que se mantienen en inglés, términos técnicos con una representación preferente, palabras de marca que transmiten un tono específico. Decláralos en tu repositorio y Glossia los aplica a toda traducción futura.

Un glosario reside en dos tipos de archivos que ya estás utilizando:

- `L10N.md` declara los **términos**: qué es la palabra y qué significa. Esto es lo mismo para cada lenguaje.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Los revisores de cada idioma son dueños de su propio archivo.

Si su cuenta también tiene un glosario en Glossia, los dos se combinan en el momento de la traducción. Vea [Glosario](/docs/explanation/glossary) para las reglas y para [cuándo usar cuál](/docs/explanation/glossary#when-to-use-which).

## 1. Declara los términos en L10N.md

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

Cada término necesita un `source`, la palabra tal como aparece en tu texto. Un `definition` ayuda al modelo a decidir si una coincidencia es realmente el concepto que quieres. `case_sensitive: true` hace que `API` coincida sin coincidir con "api" en el texto.

## 2. Tradúcelos en el archivo de cada idioma

Crea o abre `L10N/<locale>.md` junto a tu `L10N.md` y mapa cada término a su traducción aprobada:

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

Las claves son el `source` del término. Un idioma sin traducción para un término recaerá en el glosario de la cuenta, o dejará que el modelo elija.

## 3. Añade un término que solo necesita un idioma

Un archivo de idioma puede traducir una palabra que `L10N.md` no declare. La regla entonces solo se aplica a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Atribuye un id estable a un término

Cuando la misma palabra necesita un significado preciso, o quieres renombrar el `source` de un término más tarde, dale un `id` y clave sus traducciones por ese id:

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

## 5. Refina el glosario para una parte del repositorio

Un `L10N.md` anidado o `L10N/<locale>.md` hereda de sus directorios padre y puede agregar o sobreescribir entradas para su subárbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos de español bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6. Realiza el commit y el push

Guarda el cambio y envíalo. En la próxima ejecución de traducción, Glossia volverá a traducir solo los archivos que usen los términos que agregaste o cambiaste, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos conservan sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y usa solo el glosario de la cuenta, por lo que verifica las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parezca aplicarse.

## Vea también

- [Referencia de Glosario](/docs/reference/glossary): cada campo y regla de validación.
- [Glosario](/docs/explanation/glossary): cómo los glosarios del repositorio y de la cuenta se combinan.
- [Referencia de L10N.md](/docs/reference/l10n-md): los otros campos del frontmatter.
