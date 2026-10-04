%{
  title: "L10N.md",
  summary: "Referencia para configuraciones de traducción del repositorio y contexto.",
  category: "referencia",
  section: "translation",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, qué idiomas objetivo utilizar y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre los marcadores `---`.
2. Markdown debajo del frontmatter con contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El valor opcional `model` es un manejador de modelo de cuenta.

## Campos de frontmatter

| Field | Type | Required | Description |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto `en`. |
| `model` | string | no | Manejador de modelo de cuenta. Glossia usa el valor predeterminado de la cuenta cuando se omite y reporta un error cuando el manejador explícito no existe. |
| `sources` | map or list | for a top-level rule | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | map or list | when sources are configured | Códigos de región objetivo. Un mapa puede asociar un código de región con un nombre de idioma. |
| `output` | string | when no source mapping or `target_path` supplies a destination | Plantilla de archivo de salida. |
| `target_path` | string | when no source mapping or `output` supplies a destination | Plantilla de directorio base para archivos traducidos. |
| `translate` | list | no | Múltiples reglas de traducción, cada una con sus propias fuentes y ajustes opcionales. |
| `exclude` | list | no | Patrones de archivos a omitir. |
| `preserve` | list | no | Tipos de contenido que deben permanecer inalterados, como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Guía adicional para este ámbito o regla. |
| `validation` | list | for file extensions without a built-in adapter | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto a no cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | map | no | Comandos de verificación con nombres disponibles para el flujo de trabajo de traducción. |
| `retries` | integer | no | Número de intentos de repetición después de una verificación fallida. Por defecto `2`. |
| `locale` | string | no | Región adjunta a un archivo de contexto específico para región. |
| `glossary` | list or map | no | En `L10N.md`, una lista de términos de glosario. En `L10N/<locale>.md`, un mapa desde cada término hasta su traducción en ese idioma. Los archivos anidados se suman a y sobrescriben las entradas heredadas. Consulte la [referencia de glosario](/docs/reference/glossary). |

Desconocido campos de frontmatter se ignoran.

## Formatos de archivo

Glossia tiene un manejo integrado para archivos de Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objeto portátil y texto plano. Otras extensiones de archivo fallan al planificar a menos que el `L10N.md` aplicable declare un comando `validation`. Esto evita silenciosamente tratar un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato haya sido escrito temporalmente a su ruta de destino real. Puede invocar el parser nativo, el compilador o el comando de compilación del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

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

## Idiomas objetivo

Una lista utiliza cada código de localización como identificador de idioma:

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
| `{locale}` o `{lang}` | Código de localización objetivo. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Reglas múltiples

Usa `translate` cuando diferentes grupos de contenido necesiten destinos o comprobaciones diferentes:

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

Los valores de una regla sobrescriben los valores heredados del archivo que la rodea.

## Contexto delimitado

Glossia lee los archivos `L10N.md` desde la raíz del repositorio hacia el archivo fuente:

- La configuración del progenitor proporciona valores predeterminados.
- Un archivo más profundo sobrescribe los campos para su directorio.
- El contexto de Markdown se acumula desde el progenitor hasta el hijo.
- La orientación específica por idioma y un controlador de modelo específico por idioma pueden vivir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga orientaciones de tono generales en la raíz y coloque orientaciones específicas de área de producto o idioma cerca del contenido que afecta.