%{
  title: "L10N.md",
  summary: "Referencia para configuraciones de traducción del repositorio y contexto.",
  category: "referencia",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, qué idiomas tocar, y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subdirectorios.

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

Las credenciales del proveedor pertenecen a la configuración de cuenta, nunca en `L10N.md`. El valor opcional `model` es un identificador de modelo de cuenta.

## Campos frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto `en`. |
| `model` | string | no | Identificador de modelo de cuenta. Glossia usa el predeterminado de la cuenta cuando se omite y reporta un error cuando un identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran las fuentes | Códigos de idioma objetivo. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | string | cuando no hay mapeo de origen o `target_path` suministra un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` suministra un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Varias reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | lista | no | Patrones de archivo que deben omitirse. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o uniform resource locators. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Guía adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin un adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta real de destino y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación nombrados disponibles para el flujo de traducción. |
| `retries` | entero | no | Número de intentos de reintentos después de una verificación fallida. Por defecto `2`. |
| `locale` | string | no | Idioma adjunto a un archivo de contexto de idioma específico. |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene manejo integrado para archivos Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objeto portátil y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que el `L10N.md` aplicable declare un comando de `validation`. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato haya sido escrito temporalmente a su ruta real de destino. Puede invocar el analizador nativo, el compilador o el comando de compilación del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapeos de origen

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

Una lista utiliza el código de cada región como identificador de idioma:

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
| `{locale}` o `{lang}` | Código de la región objetivo. |
| `{relpath}` | Ruta del archivo de origen relativa al patrón coincidido. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Múltiples reglas

Use `translate` cuando diferentes grupos de contenido necesiten destinos o verificaciones diferentes:

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

Los valores de las reglas las sobrescriben de los valores heredados del archivo circundante.

## Contexto con alcance

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo fuente:

- La configuración de los padres proporciona valores predeterminados.
- Un archivo más profundo sobrescribe los campos de su directorio.
- El contexto de Markdown se acumula de padre a hijo.
- La orientación específica por localización y un manejador de modelo específico por localización pueden vivir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga orientaciones generales de voz en la raíz, mientras coloca la orientación específica del área de producto o del idioma cerca del contenido que afecta.