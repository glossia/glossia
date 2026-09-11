%{
  title: "L10N.md",
  summary: "Referencia para la configuración de traducción del repositorio y el contexto.",
  category: "referencia",
  order: 1
}
---
`L10N.md` le indica a Glossia qué archivos traducir, dónde deben ir los archivos traducidos, qué idiomas objetivo configurar y qué contexto debe orientar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con alcance específico en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre los marcadores `---`.
2. Markdown debajo de la cabecera con contexto de producto, audiencia, voz o dominio.

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

## Campos frontmatter

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `source_language` | texto | no | Localización de origen para este ámbito. Por defecto `en`. |
| `model` | texto | no | Manejador de modelo de cuenta. Glossia utiliza el predeterminado de la cuenta cuando se omite y reporta un error cuando un manejador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivo de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando las fuentes están configuradas | Códigos de localización objetivo. Un mapa puede asociar un código de localización con un nombre de idioma. |
| `output` | texto | cuando no hay mapeo de origen o `target_path` provee un destino | Plantilla de archivo de salida. |
| `target_path` | texto | cuando no hay mapeo de origen o `output` provee un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | lista | no | Patrones de archivo para omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | texto | no | `preserve` por defecto, o `translate`. |
| `prompt` | texto | no | Guia adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin un adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su destino real y debe devolver un estado distinto de cero si el archivo es inválido. |
| `check_cmd` | texto | no | Un comando de verificación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de verificación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de repetición después de una verificación fallida. Por defecto `2`. |
| `locale` | texto | no | Localización adjunta a un archivo de contexto específico a nivel de idioma. |

Se ignoran los campos frontmatter desconocidos.

## Formatos de archivo

Glossia tiene un manejo integrado para Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objetos portátiles y archivos de texto plano. Otras extensiones de archivo fallan durante la planificación a menos que el `L10N.md` aplicable declare un comando de `validation`. Esto evita silenciosamente tratar un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato haya sido escrito temporalmente a su destino real. Puede invocar el analizador, compilador o comando de construcción nativo del repositorio. Glossia restaura el objetivo anterior después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapeos de origen

La forma más clara asigna cada patrón de origen a una plantilla de salida:

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

Una lista utiliza cada código de ámbito como identificador de idioma:

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
| `{locale}` o `{lang}` | Código de ámbito del idioma objetivo. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre de archivo de origen sin su extensión. |
| `{ext}` | Extensión de archivo de origen sin el punto inicial. |

## Reglas múltiples

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

Los valores de la regla sobrescriben los valores heredados del archivo circundante.

## Contexto de alcance

Glossia lee los archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- Las configuraciones de padres proporcionan valores predeterminados.
- Un archivo más profundo sobrescribe los campos de su directorio.
- El contexto de Markdown se acumula de padres a hijo.
- La orientación específica de ámbito y los manejadores de modelo específicos de ámbito pueden vivir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga orientación de voz general en la raíz mientras coloca orientación específica del área del producto o del idioma cerca del contenido que afecta.