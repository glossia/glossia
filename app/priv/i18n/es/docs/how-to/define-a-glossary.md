%{
  title: "Definir un glosario",
  summary:
    "Declara los términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Tutorial",
  section: "translation",
  order: 6
}
---

Tu equipo ya tiene términos que deben traducirse de una manera específica: nombres de productos que permanecen en inglés, términos técnicos con una renderización preferida, palabras de marca que transmiten un tono específico. Decláralos en tu repositorio y Glossia los aplicará a cada traducción futura.

Un glosario reside en dos tipos de archivos que ya utilizas:

- `L10N.md` declara los **términos**: qué palabra es y qué significa. Esto es lo mismo para cada idioma.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Los revisores de cada idioma tienen su propio archivo.

Si tu cuenta también tiene un glosario en Glossia, los dos se fusionan en el momento de la traducción. Consulta [Glosario](/docs/explanation/glossary) para las reglas y para [cómo elegir cuándo usar cuál](/docs/explanation/glossary#when-to-use-which).

## 1. Declara los términos en L10N.md

Añade una `glossary` lista a la cabecera de tu `L10N.md` raíz:

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

Cada término necesita un `source`, la palabra tal como aparece en tu texto. Un `definition` ayuda al modelo a decidir si una coincidencia es realmente el concepto que pretendes. `case_sensitive: true` hace que `API` coincida sin que coincida "api" en la prosa.

## 2. Tradúcelos en el archivo de cada idioma.

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

Las claves son la `source` del término. Un idioma sin traducción para un término recurre al glosario de la cuenta, o deja que el modelo elija.

## 3. Añade un término del que solo necesita un idioma.

Un archivo de idioma puede traducir una palabra que `L10N.md` no declare. Entonces, la regla solo se aplica a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Da un id estable a un término.

Cuando una misma palabra necesita un significado preciso, o quieres renombrar la `source` de un término más tarde, dale un `id` y usa ese id para las claves de sus traducciones:

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

## 5. Refina el glosario para una parte del repositorio.

Un `L10N.md` anidado o `L10N/<locale>.md` hereda de sus directorios padres y puede añadir o sobreescribir entradas para su subárbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos de español bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6. Commit y push

Realiza el commit del cambio y el push. En la siguiente ejecución de traducción, Glossia retraduce solo los archivos que usen los términos que añadiste o cambiaste, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos conservan sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y usa solo el glosario de la cuenta, así que revisa las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parezca aplicarse.

## Ver también

- [Referencia de Glosario](/docs/reference/glossary): cada campo y regla de validación.
- [Glosario](/docs/explanation/glossary): cómo se combinan el glosario del repositorio y de la cuenta.
- [Referencia L10N.md](/docs/reference/l10n-md): los otros campos de cabecera.
