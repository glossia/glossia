%{
  title: "L10N.md",
  summary: "Referencia para la configuración de traducción del repositorio y contexto.",
  category: "referencia",
  section: "translation",
  order: 1
}
---

`L10N.md` indica a Glossia qué archivos traducir, a dónde pertenecerán los archivos traducidos, a qué idiomas dirigirse y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales de ámbito en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [Lenguaje de marcado YAML](https://yaml.org/) frontmatter entre `---` marcadores.
2. El Markdown que se encuentra debajo de la frontmatter con contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El valor opcional `model` es el identificador de modelo de la cuenta.

## Campos de frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto a `en`. |
| `model` | string | no | Identificador de modelo de la cuenta. Glossia utiliza el predeterminado de la cuenta cuando se omite y reporta un error cuando un identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando las fuentes están configuradas | Códigos de idioma de destino. Un mapa puede asociar un código de idioma con el nombre del idioma. |
| `output` | string | cuando no hay mapeo de origen o `target_path` provee un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` provee un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | lista | no | Patrones de archivo para omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores o localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Orientación adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin adaptador incorporado | Un comando de validación seguido de sus argumentos. El comando recibe al candidato en su ruta de destino real y debe devolver un estado no nulo si el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación nombrados disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos después de una comprobación fallida. Por defecto a `2`. |
| `locale` | string | no | Idioma unido a un archivo de contexto específico del idioma. |
| `glossary` | lista o mapa | no | En `L10N.md`, una lista de términos del glossario. En `L10N/<locale>.md`, un mapa desde cada término a su traducción en ese idioma. Los archivos anidados agregan entradas heredadas y las sobrescriben. Consulte el [glosario de referencia](/docs/reference/glossary). |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene un manejo incorporado para Markdown, Notación de objeto JavaScript, Lenguaje de marcado YAML, objeto portátil y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que la extensión de archivo `L10N.md` declare un comando de `validation`. Esto evita silenciosamente tratar un formato estructurado propietario como texto sin restricciones.

En Markdown, solo el texto corrido se traduce: párrafos, títulos, elementos de lista, celdas de tabla, los `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, y `caption` atributos de componentes y HTML, y el texto de un HTML `<summary>`. Cada otro byte, incluido el código, destinos de enlace, componentes, alertas y anclajes de título explícitos, se mantienen exactamente como en la fuente. Consulte [recuperación de traducción](/docs/explanation/translation-recovery) para ver cómo funciona esto.

El comando de validación se ejecuta después de que el candidato ha sido escrito temporalmente a su ruta de destino real. Puede invocar el parser nativo, el compilador o el comando de compilación del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

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

Una lista usa cada código de idioma como identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Un mapa puede agregar un nombre de idioma legible:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de salida

| Variable | Valor |
|---|---|
| `{locale}` o `{lang}` | Código de idioma de destino. |
| `{relpath}` | Ruta de origen relativa al patrón de coincidencia. |
| `{basename}` | Nombre de archivo de origen sin su extensión. |
| `{ext}` | Extensión de archivo de origen sin el punto inicial. |

## Múltiples reglas

Utilice `translate` cuando diferentes grupos de contenido necesiten diferentes destinos o verificaciones:

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

Los valores de regla sobrescriben los valores heredados del archivo circundante.

## Contexto delimitado

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- Las configuraciones del padre proporcionan valores predeterminados.
- Un archivo más profundo sobrescribe campos para su directorio.
- El contexto de Markdown se acumula desde el padre hasta el hijo.
- La orientación específica del idioma y un manejador de modelo específico del idioma pueden residir en `L10N/<locale>.md`.

Esto permite a un repositorio mantener la orientación de tono general en la raíz mientras coloca la orientación específica del área del producto o del idioma cerca del contenido que afecta.
