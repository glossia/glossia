%{
  title: "L10N.md",
  summary: "Referencia para la configuración y el contexto de traducción del repositorio.",
  category: "referencia",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, dónde deben ubicarse los archivos traducidos, qué idiomas objetivo utilizar y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con alcance en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML no es un lenguaje de marcado](https://yaml.org/) frontmatter entre `---` marcadores.
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

Las credenciales del proveedor pertenecen a la configuración de cuenta, nunca en `L10N.md`. El opcional `model` el valor es un identificador del modelo de cuenta.

## Campos frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto `en`. |
| `model` | cadena | no | Identificador de modelo de cuenta. Glossia utiliza el valor predeterminado de la cuenta cuando se omite e informa un error cuando no existe un identificador explícito. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de fuente. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando están configuradas las fuentes | Códigos de idioma objetivo. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | cadena | cuando no existe mapeo de fuente o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` proporciona un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | list | no | Múltiples reglas de traducción, cada una con sus propios orígenes y sobrescritas opcionales. |
| `exclude` | list | no | Patrones de archivo para omitir. |
| `preserve` | list | no | Tipos de contenido que deben mantenerse sin cambios, como marcadores de posición o identificadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | cadena | no | Orientación adicional para este ámbito o regla. |
| `validation` | list | para extensiones de archivo sin adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe al candidato en su ruta de destino real y debe devolver un estado no nulo cuando el archivo no sea válido. |
| `check_cmd` | string | no | Un comando de comprobación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | map | no | Comandos de comprobación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | integer | no | Número de reintentos tras una comprobación fallida. Por defecto a `2`. |
| `locale` | string | no | Localización adjunta a un archivo de contexto específico de la localización. |

Los campos de frontmatter desconocidos son ignorados.

## Formatos de archivo

Glossia tiene un manejo integrado para Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objeto portable y archivos de texto plano. Otras extensiones de archivo no se planifican a menos que el correspondiente `L10N.md` declara un `validation` comando. Esto evita silenciosamente tratar un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente en su ruta de destino real. Puede invocar el analizador, compilador o comando de construcción nativo del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

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

Una lista usa cada código de región como su identificador de idioma:

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
| `{locale}` o `{lang}` | Código del idioma objetivo. |
| `{relpath}` | Ruta de origen relativa a la regla coincidente. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Múltiples reglas

Utilice `translate` cuando diferentes grupos de contenido necesiten destinos o verificaciones diferentes:

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

## Contexto de ámbito

Glossia lee archivos `L10N.md` desde la raíz del repositorio hasta el archivo de origen:

- La configuración de los padres establece los valores predeterminados.
- Un archivo más profundo sobrescribe campos para su directorio.
- El contexto Markdown se acumula desde el padre hasta el hijo.
- Las guías específicas de región y el manejador de modelo específico de región pueden haber en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga guías generales de voz en la raíz mientras coloca guías de área de producto o idioma específicas cerca del contenido que afecta.