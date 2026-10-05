%{
  title: "Define un glosario",
  summary:
    "Declara los términos en L10N.md y sus traducciones aprobadas en el archivo de sobrescritura de cada idioma.",
  category: "Guía",
  section: "translation",
  order: 6
}
---
Su equipo ya tiene términos que deben traducirse de una forma específica: nombres de productos que permanecen en inglés, términos técnicos con una representación preferida, y palabras de marca que transmiten un tono específico. Declárelos en su repositorio y Glossia los aplicará a todas las traducciones futuras.

Un glosario reside en dos tipos de archivos que ya utiliza:

- `L10N.md` declara los **términos**: qué es la palabra y qué significa. Esto es lo mismo para todos los idiomas.
- `L10N/<locale>.md` declara las **traducciones** para un idioma. Los revisores de cada idioma poseen su propio archivo.

Si su cuenta también tiene un glosario en Glossia, ambos se fusionan en el momento de la traducción. Consulte [Glosario](/docs/explanation/glossary) para las reglas y para [cuándo usar cuál](/docs/explanation/glossary#when-to-use-which).

## 1\. Declare los términos en L10N.md

Añada una lista `glossary` al frontmatter de su archivo raíz `L10N.md`:

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

Cada término necesita un `source`, la palabra tal como aparece en su texto. Una `definition` ayuda al modelo a determinar si una coincidencia es realmente el concepto que tiene en mente. `case_sensitive: true` hace que `API` coincida sin coincidir con "api" en el texto.

## 2\. Córtelas en el archivo de cada idioma

Cree o abra `L10N/<locale>.md` junto a su `L10N.md` y mapee cada término a su traducción aprobada:

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

Las claves son el `source` del término. Un idioma sin traducción para un término utiliza el glosario de la cuenta por defecto, o deja que el modelo elija.

## 3\. Añada un término que solo necesite un idioma

Un archivo de idioma puede traducir una palabra que `L10N.md` no declara. La regla se aplica solo a ese idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Otorgue a un término un id estable

Cuando la misma palabra necesita un significado preciso, o desea renombrar el `source` de un término más tarde, aúnéle un `id` y clave sus traducciones por ese id:

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

## 5\. Refine el glosario para una parte del repositorio

Un `L10N.md` o `L10N/<locale>.md` anidados hereda de sus directorios padres y puede agregar o reemplazar entradas para su subárbol:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Los archivos en español bajo `marketing/` traducen "commit" como `compromiso`; el resto del repositorio mantiene `commit`.

## 6\. Compromete y envía

Realiza el cambio y haz el commit y el push. En la próxima ejecución de traducción, Glossia vuelve a traducir solo los archivos que usan los términos que agregó o modificó, en los idiomas cuyas traducciones cambiaron. Los archivos que no contienen esos términos mantienen sus traducciones existentes.

Si un glosario tiene un error, Glossia ignora el glosario del repositorio para los archivos afectados y utiliza solo el glosario de la cuenta, por lo que revise las [reglas de validación](/docs/reference/glossary#validation) cuando un término no parezca aplicarse.

## Vea también

- [Referencia del glosario](/docs/reference/glossary): todos los campos y reglas de validación.
- [Glosario](/docs/explanation/glossary): cómo se combinan los glosarios del repositorio y de la cuenta.
- [Referencia de L10N.md](/docs/reference/l10n-md): los otros campos del frontmatter.