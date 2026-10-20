%{
  title: "L10N.md",
  summary: "Referencia para la configuración y el contexto de traducción del repositorio.",
  category: "referencia",
  section: "translation",
  order: 1
}
---

`L10N.md` indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, qué idiomas comparar, y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales acotados en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML no es lenguaje de marcado](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown debajo del frontmatter con contexto de producto, audiencia, tono o dominio.

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

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `source_language` | cadena | no | Idioma de origen para este alcance. Por defecto es `en`. |
| `model` | cadena | no | Identificador de modelo de cuenta. Glossia utiliza el valor predeterminado de la cuenta cuando se omite e informa un error cuando un identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran las fuentes | Códigos de idioma de destino. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | cadena | cuando no hay mapeo de origen o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | cadena | cuando no hay mapeo de origen o `output` proporciona un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescripciones opcionales. |
| `exclude` | lista | no | Patrones de archivo para omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer inalterados, como marcadores de posición o identificadores de ubicación de recursos uniformes. |
| `frontmatter` | cadena | no | `preserve` por defecto, o `translate`. |
| `prompt` | cadena | no | Guía adicional para este alcance o regla. |
| `validation` | lista | para extensiones de archivo sin adaptador integrado. | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo sea inválido. |
| `check_cmd` | cadena | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación nombrados disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de reintento tras una verificación fallida. Por defecto es `2`. |
| `locale` | cadena | no | Idioma adjunto a un archivo de contexto específico del idioma. |
| `glossary` | lista o mapa | no | En `L10N.md`, una lista de términos del glosario. En `L10N/<locale>.md`, un mapa de cada término a su traducción en ese idioma. Los archivos anidados se suman a y sobrescriben las entradas heredadas. Consulte la [referencia del glosario](/docs/reference/glossary). |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene soporte integrado para Markdown, JavaScript Object Notation, YAML no es lenguaje de marcado, objetos portátiles y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que el `L10N.md` aplicable declare un `validation` comando. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricción.

En Markdown, solo el texto se traduce: párrafos, encabezados, elementos de lista, celdas de tabla, los `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, y `caption` de componentes y HTML, y el texto de un `<summary>` HTML. Cada otro byte, incluido el código, los destinos de enlace, los componentes, las alertas y las etiquetas explícitas de encabezado, se mantiene exactamente como en el origen. Consulte [recuperación de traducción](/docs/explanation/translation-recovery) para ver cómo funciona esto.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente a su ruta de destino real. Puede invocar el analizador nativo, compilador o comando de construcción del repositorio. Glossia restaura el objetivo anterior después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapeos de origen

La forma más clara mapea cada patrón de origen a una plantilla de salida:

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

## Idiomas de destino

Una lista utiliza cada código de idioma como su identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Un mapa puede añadir un nombre de idioma legible:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de salida

| Variable | Valor |
|---|---|
| `{locale}` o `{lang}` | Código de idioma de destino. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre de archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Reglas múltiples

Utilice `translate` cuando diferentes grupos de contenido requieran destinos o verificaciones distintas:

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

Los valores de la regla sobrescriben los valores heredados del archivo circundante.

## Contexto delimitado

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- La configuración del padre proporciona valores predeterminados.
- Un archivo anidado sobrescribe los campos de su directorio.
- El contexto de Markdown se acumula del padre al hijo.
- La orientación específica del idioma y el identificador de modelo específico del idioma pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga directrices de tono generales en la raíz, al mismo tiempo que coloca directrices específicas de área de producto o idioma cerca del contenido que afecta.
