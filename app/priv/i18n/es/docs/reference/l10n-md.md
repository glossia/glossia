%{
  title: "L10N.md",
  summary: "Referencia para la configuración y contexto de traducción del repositorio.",
  category: "Referencia",
  order: 1
}
---
`L10N.md` indica a Glossia qué archivos traducir, dónde ubicar los archivos traducidos, qué idiomas procesar y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subcarpetas.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre los marcadores `---`.
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

Las credenciales del proveedor pertenecen a la configuración de la cuenta, nunca en `L10N.md`. El valor opcional `model` es una referencia al modelo de cuenta.

## Campos de frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma origen para este ámbito. Por defecto `en`. |
| `model` | string | no | Referencia al modelo de cuenta. Glossia usa el predeterminado de la cuenta si se omite, y reporta un error si el identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran fuentes | Códigos de idioma destino. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | string | cuando no hay mapeo de origen o `target_path` suministra un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` suministra un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobreescribibles opcionales. |
| `exclude` | lista | no | Patrones de archivo a omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o identificadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Indicaciones adicionales para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin adaptador incorporado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación nombrados disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de repetición tras una verificación fallida. Por defecto `2`. |
| `locale` | string | no | Idioma adjuntado a un archivo de contexto específico para idioma. |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene un manejo integrado para archivos Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objetos portables y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que el `L10N.md` aplicable declare un comando de `validation`. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente en su ruta de destino real. Puede invocar el analizador nativo, el compilador o el comando de construcción del repositorio. Glossia restaura el objetivo anterior tras cada intento de validación y solo escribe el candidato aceptado posteriormente.

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
| `{basename}` | Nombre de archivo de origen sin la extensión. |
| `{ext}` | Extensión de archivo de origen sin el punto inicial. |

## Reglas múltiples

Use `translate` cuando se necesiten destinos o comprobaciones diferentes para grupos de contenido distintos:

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

Los valores de las reglas sobrescriben los valores heredados del archivo circundante.

## Contexto de ámbito

Glossia lee archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- La configuración del padre establece valores predeterminados.
- Un archivo más profundo sobrescribe los campos de su directorio.
- El contexto de Markdown se acumula de padre a hijo.
- La orientación específica de la localización y un manipulador específico de la localización pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga una orientación de tono amplia en la raíz mientras coloca orientación específica del área de producto o del idioma cerca del contenido al que afecta.