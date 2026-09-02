%{
  title: "GLOSSIA.md",
  summary: "Referencia para la configuración de traducción del repositorio y contexto.",
  category: "Referencia",
  order: 1
}
---
`GLOSSIA.md` indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, a qué idiomas dirigirse y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. [Lenguaje de marcado no es YAML](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown por debajo del frontmatter con contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen a la configuración de cuenta, nunca en`GLOSSIA.md`. El valor opcional `model` es un identificador de modelo de cuenta.

## Campos del frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | cadena | no | Idioma fuente para este ámbito. Valor predeterminado es `en`. |
| `model` | cadena | no | Identificador de modelo de cuenta. Glossia usa el valor predeterminado de cuento cuando se omita y reporta un error cuando un identificador explícito no existe. |
| `sources` | mapa o lista | para una regla principal | Patrones de archivos fuente. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran sources | Códigos de idioma de destino. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | cadena | cuando no hay mapeo de origen o `target_path` proporciona un destino | Plantilla de archivo de salida. |
| `target_path` | cadena | cuando no hay mapeo de origen o `output` proporciona un destino | Máscara de directorio base para archivos traducidos. |
| `translate` | lista | no | Múltiples reglas de traducción, cada una con sus propias fuentes y superposiciones opcionales. |
| `exclude` | lista | no | Patrones de archivos a excluir. |
| `preserve` | lista | no | Tipos de contenido que deben mantenerse sin cambios, tales como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | cadena | no | `preserve` por defecto, o `translate`. |
| `prompt` | cadena | no | Guía adicional para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | cadena | no | Un comando de comprobación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de comprobación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de intentos de reintento después de una comprobación fallida. Valor predeterminado es `2`. |
| `locale` | cadena | no | Idioma adjunto a un archivo de contexto específico del idioma. |

Los campos desconocidos de frontmatter son ignorados.

## Formatos de archivo

Glossia tiene manejo integrado para Markdown, Notas Objetos JavaScript, YAML Ain't Markup Language, objetos portátiles y archivos de texto plano. Otras extensiones de archivo fallan en la planificación a menos que el `GLOSSIA.md` declaring declare `validation` un comando. Esto evita silenciosamente tratar un formato estructurado propietario como texto no restringido.

El comando de validación se ejecuta después de que el candidato se haya temporalmente escrito a su ruta de destino real. Puede invocar el analizador nativo, compilador o comando de compilación del repositorio. Glossia restablece el anterior objetivo después de cada intento de validación y solo escribe el candidato aceptado después.

## Mapeos de origen

La forma más clara es mapear cada patrón fuente a una plantilla de salida:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Una lista de orígenes también es válida, pero necesita `output` o `target_path` para definir el destino:

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

Un mapa puede agregar un nombre de idioma legible:

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
| `{basename}` | Nombre de archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

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

## Contexto de ámbito

Glossia lee archivos `GLOSSIA.md` desde la raíz del repositorio hacia el archivo de origen:

- La configuración del progenitor provee los valores por defecto.
- Un archivo más profundo sobrescribe los campos para su directorio.
- El contexto de Markdown se acumula desde el progenitor al hijo.
- La orientación específica de localización y el manejador de modelo específico de localización pueden residir en `GLOSSIA/<locale>.md`.

Esto permite que un repositorio mantenga una orientación de voz amplia en la raíz mientras coloca orientación específica del área de producto o idioma cerca del contenido que afecta.