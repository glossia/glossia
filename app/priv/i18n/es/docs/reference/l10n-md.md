%{
  title: "L10N.md",
  summary: "Referencia para configuraciones y contexto de traducción del repositorio.",
  category: "referencia",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, qué idiomas objetivo y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML no es lenguaje de marcado](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown debajo del frontmatter con el contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El opcional `model` valor es un identificador de modelo de cuenta.

## Campos de frontmatter

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto `en`. |
| `model` | cadena | no | Manejo del modelo de cuenta. Glossia usa el valor predeterminado de la cuenta si se omite e informa un error cuando no existe un identificador explícito. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran las fuentes | Códigos de localización objetivo. Un mapa puede asociar un código de localización con un nombre de idioma. |
| `output` | cadena | cuando no hay mapeo de origen o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de fuente o `output` proporciona un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | list | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | list | no | Patrones de archivo para omitir. |
| `preserve` | list | no | Tipos de contenido que deben permanecer inalterables, como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Orientación adicional para este ámbito o regla. |
| `validation` | list | para extensiones de archivo sin adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | map | no | Comandos de verificación nombrados disponibles para el flujo de trabajo de traducción. |
| `retries` | integer | no | Número de intentos de reintento tras una verificación fallida. Por defecto a `2`. |
| `locale` | texto | no | Localización adjunta a un archivo de contexto específico de localización. |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene soporte integrado para Markdown, Notación de Objetos JavaScript, YAML no es lenguaje de marcado, Objetos Portátiles y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que la `L10N.md` declara un `validation` comando. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta tras que el candidato se haya escrito temporalmente en su ruta de destino real. Puede invocar el analizador nativo, el compilador o el comando de construcción del repositorio. Glossia restaura el destino anterior tras cada intento de validación y solo escribe el candidato aceptado después.

## Mapas de origen

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

Una lista usa cada código de idioma como su identificador de idioma:

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
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre de archivo de origen sin extensión. |
| `{ext}` | Extensión de archivo de origen sin el punto inicial. |

## Reglas múltiples

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

Los valores de las reglas anulan los valores heredados del archivo circundante.

## Contexto acotado

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- Las configuraciones padre proporcionan valores predeterminados.
- Un archivo más profundo anula campos para su directorio.
- El contexto de Markdown se acumula de padre a hijo.
- Las directivas específicas del idioma y un manejador de modelo específico del idioma pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga directrices generales de voz en la raíz mientras coloca la orientación específica del área de producto o idioma cerca del contenido que afecta.