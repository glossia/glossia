%{
  title: "L10N.md",
  summary: "Referencia para la configuración de traducción del repositorio y el contexto.",
  category: "referencia",
  section: "translation",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, dónde pertenecen los archivos traducidos, los idiomas de destino y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo principal y archivos con ámbito adicionales en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre los marcadores `---`.
2. Markdown debajo de la frontmatter con contexto del producto, audiencia, voz o dominio.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El valor opcional `model` es un identificador de modelo de cuenta.

## Campos de frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | texto | no | Idioma fuente para este ámbito. Por defecto `en`. |
| `model` | texto | no | Identificador de modelo de cuenta. Glossia usa el predeterminado de la cuenta cuando se omite e informa un error si el identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivo fuente. Los valores del mapa pueden plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran fuentes | Códigos de idioma objetivo. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | texto | cuando no hay mapeo de fuente o `target_path` provee un destino | Plantilla de archivo de salida. |
| `target_path` | texto | cuando no hay mapeo de fuente o `output` provee un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y overrides opcionales. |
| `exclude` | lista | no | Patrones de archivos para omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como repositorios o locaciones de recursos uniformes. |
| `frontmatter` | texto | no | `preserve` por defecto, o `translate`. |
| `prompt` | texto | no | Orientación adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | texto | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación nombrados disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de reintento después de una verificación fallida. Por defecto `2`. |
| `locale` | texto | no | Idioma adjunto a un archivo de contexto específico de idioma. |
| `glossary` | lista o mapa | no | En `L10N.md`, una lista de términos de vocabulario. En `L10N/<locale>.md`, un mapa desde cada término hasta su traducción en ese idioma. Los archivos anidados suman y sobreescriben las entradas heredadas. Consulte la [referencia de glosario](/docs/reference/glossary). |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene manejo integrado para archivos Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objeto portátil y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que el `L10N.md` aplicable declare un comando de `validation`. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

En Markdown, solo se traduce la prosa: párrafos, encabezados, elementos de lista, celdas de tabla, `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label` y `caption` de componentes y HTML, y el texto de un `<summary>` HTML. Cada otro byte, incluido el código, los destinos de los enlaces, componentes, alertas y anclas de encabezado explícitos, se conserva exactamente como en la fuente. Consultar [recuperación de traducción](/docs/explanation/translation-recovery) para ver cómo funciona esto.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente en su ruta de destino real. Puede invocar el analizador nativo, el compilador o el comando de compilación del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado posteriormente.

## Mapas de origen

La forma más clara asigna cada patrón de origen a una plantilla de salida:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Una lista de origen también es válida, pero necesita `output` o `target_path` para definir el destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas objetivo

Una lista utiliza cada código de localización como su identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Un mapa puede agregar un nombre legible de idioma:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de salida

| Variable | Valor |
|---|---|
| `{locale}` or `{lang}` | Código de localización objetivo. |
| `{relpath}` | Ruta de origen relativa al patrón coincidido. |
| `{basename}` | Nombre del archivo de origen sin la extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Varias reglas

Use `translate` cuando diferentes grupos de contenido necesiten diferentes destinos o validaciones:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Los valores de las reglas anulan los valores heredados del archivo circundante.

## Alcance del contexto

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- La configuración del padre proporciona valores por defecto.
- Un archivo más profundo sobrescribe campos para su directorio.
- El contexto de Markdown se acumula del padre al hijo.
- Las directrices de localización específicas y un manejador de modelo de localización específico pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga directrices de tono amplias en la raíz, colocando al mismo tiempo directrices específicas de área de producto o idioma junto al contenido que afecta.