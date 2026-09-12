%{
  title: "L10N.md",
  summary: "Referencia para la configuración de traducción del repositorio y el contexto.",
  category: "referencia",
  order: 1
}
---
`L10N.md` informa a Glossia a qué archivos traducir, a dónde pertenecen los archivos traducidos, qué idiomas adaptar y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales acotados en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown debajo del frontmatter con contexto de producto, público, voz o dominio.

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

Las credenciales del proveedor deben ir en la configuración de la cuenta, nunca en `L10N.md`. El valor opcional `model` es un manual de modelo de cuenta.

## Campos del frontmatter

| Campos | Tipo | Requerido | Descripción |
|---|---|---|---|
| `source_language` | string | no | Local de origen para este ámbito. Por defecto es `en`. |
| `model` | string | no | Manual de modelo de cuenta. Glossia utiliza el por defecto cuando no se especifica y informa un error cuando un manual explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores de mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran fuentes | Códigos de local de destino. Un mapa puede asociar un código de local con un nombre de lenguaje. |
| `output` | string | cuando no hay mapeo de origen o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` proporciona un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y Overrides opcionales. |
| `exclude` | lista | no | Patrones de archivo a excluir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o indicadores de ubicación de recurso uniforme. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Guía adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin un adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe al candidato en su ruta de destino real y debe devolver un estado no cero cuando el archivo está inválido. |
| `check_cmd` | string | no | Un comando de comprobación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de comprobación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de repetición después de una comprobación fallida. Por defecto es `2`. |
| `locale` | string | no | Local adjunto a un archivo de contexto específico de local. |

Los campos desconocidos del frontmatter se ignoran.

## Formatos de archivos

Glossia tiene un manejo integrado para Markdown, Notación de Objeto JavaScript, YAML Ain't Markup Language, objeto portátil y archivos de texto plano. Otras extensiones de archivo fallarán en la planificación a menos que el `L10N.md` declare un `validation` comando. Esto evita tratar silenciosamente un formato estructurado propietario como texto no restringido.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente a su ruta de destino real. Puede invocar el interpretador nativo del repositorio, compilador o comando de compilación. Glossia recupera el destino anterior después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapeo de fuentes

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

Una lista utiliza cada código de localización como identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Un mapa puede añadir un nombre legible de idioma:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de salida

| Variable | Valor |
|---|---|
| `{locale}` o `{lang}` | Código del idioma objetivo. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Múltiples reglas

Usar `translate` cuando los grupos de contenido diferentes necesitan destinos o verificaciones diferentes:

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

## Contexto de ámbito

Glossia lee `L10N.md` archivos desde la raíz del repositorio hacia el archivo fuente:

- La configuración del padre proporciona valores por defecto.
- Un archivo más profundo sobrescribe los campos para su directorio.
- El contexto de Markdown se acumula de padre a hijo.
- La orientación específica del idioma y un manejador de modelos específico del idioma pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga una amplia orientación de voz en la raíz, mientras coloca la orientación específica del área del producto o del idioma cerca del contenido que afecta.