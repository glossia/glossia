%{
  title: "L10N.md",
  summary: "Referencia para configuraciones de traducción del repositorio y contexto.",
  category: "referencia",
  section: "translation",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, dónde residen los archivos traducidos, qué idiomas objetivo y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subcarpetas.

## Estructura

Cada archivo tiene dos partes:

1. [YAML no es un lenguaje de marcado](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown por debajo de la frontmatter con contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El opcional. `model` el valor es un identificador de modelo de cuenta.

## Campos de Frontmatter

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este alcance. Por defecto `en`". |
| `model` | string | no | Identificador del modelo de cuenta. Glossia usa el predeterminado de la cuenta cuando se omite y reporta un error cuando no existe un identificador explícito. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos fuente. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran las fuentes | Códigos de idioma de destino. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | string | cuando no existe mapeo de fuentes o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | cadena | cuando no hay mapeo de origen o `output` proporciona un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | lista | no | Patrones de archivos a omitir. |
| `preserve` | list | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Instrucciones adicionales para este ámbito o regla. |
| `validation` | list | para extensiones de archivo sin adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | map | no | Comandos de verificación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | integer | no | Número de intentos de reintento tras una verificación fallida. Por defecto a `2`. |
| `locale` | cadena | no | Localización adjunta a un archivo de contexto específico de localización. |
| `glossary` | lista o mapa | no | En `L10N.md`, una lista de términos del glosario. En `L10N/<locale>.md`, un mapa desde cada término a su traducción en ese idioma. Los archivos anidados añaden y sobrescriben las entradas heredadas. Consulte la [referencia del glosario](/docs/reference/glossary). |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia cuenta con manejo integrado para Markdown, Notación de Objetos de JavaScript, YAML no es un lenguaje de marcado, objetos portátiles y archivos de texto plano. Otras extensiones fallan en la planificación a menos que la aplicable `L10N.md` declares a `validation` comando. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente a su ruta de destino real. Puede invocar el parseador, el compilador o el comando de construcción nativo del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapas de origen

La forma más clara mapea cada patrón de origen a una plantilla de salida:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Una lista de fuentes también es válida, pero necesita `output` o `target_path` para definir el destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas objetivo

Una lista utiliza cada código de idioma regional como identificador:

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
| `{locale}` o `{lang}` | Código regional de destino. |
| `{relpath}` | Ruta de origen relativa al patrón coincidido. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Reglas múltiples

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

## Contexto con ámbito

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo fuente:

- La configuración de los elementos padres proporciona valores predeterminados.
- Un archivo más profundo sobrescribe los campos para su directorio.
- El contexto de Markdown se acumula de padre a hijo.
- La orientación específica del idioma y un manejador de modelo específico del idioma pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga una guía de voz amplia en la raíz, mientras coloca una guía específica del área de producto o idioma cerca del contenido al que afecta.