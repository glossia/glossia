%{
  title: "L10N.md",
  summary: "Referencia para configuraciones de traducción del repositorio y contexto.",
  category: "referencia",
  order: 1
}
---
`L10N.md` le indica a Glossia qué archivos traducir, a dónde pertenecen los archivos traducidos, a qué idiomas dirigir y qué contexto debe guiar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbito en subdirectoríos.

## Estructura

Cada archivo tiene dos partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre los marcadores `---`.
2. Markdown debajo de la frontmatter con contexto de producto, audiencia, voz o dominio.

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

Las credenciales del proveedor pertenecen en la configuración de cuenta, nunca en `L10N.md`. El valor opcional `model` es un identificador de modelo de cuenta.

## Campos de frontmatter

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | string | no | Idioma de origen para este ámbito. Por defecto `en`. |
| `model` | string | no | Identificador de modelo de cuenta. Glossia usa el predeterminado de la cuenta cuando se omite e informa un error cuando el identificador explícito no existe. |
| `sources` | map or list | para una regla de nivel superior | Patrones de archivo de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | map or list | cuando están configuradas las fuentes | Códigos de idioma objetivo. Un mapa puede asociar un código de idioma con un nombre de idioma. |
| `output` | string | cuando no hay mapeo de origen o `target_path` suministra un destino | Plantilla de archivo de salida. |
| `target_path` | string | cuando no hay mapeo de origen o `output` suministra un destino | Plantilla de directorio base para archivos traducidos. |
| `translate` | list | no | Múltiples reglas de traducción, cada una con sus propias fuentes y sobrescrituras opcionales. |
| `exclude` | list | no | Patrones de archivo a omitir. |
| `preserve` | list | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por defecto, o `translate`. |
| `prompt` | string | no | Orientación adicional para este ámbito o regla. |
| `validation` | list | para extensiones de archivo sin un adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el candidato a su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo es inválido. |
| `check_cmd` | string | no | Un comando de comprobación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | map | no | Comandos de comprobación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | integer | no | Número de intentos de reintento tras una comprobación fallida. Por defecto `2`. |
| `locale` | string | no | Idioma adjunto a un archivo de contexto específico del idioma. |

Los campos de frontmatter desconocidos se ignoran.

## Formatos de archivo

Glossia tiene soporte integrado para Markdown, Notación de Objetos JavaScript, YAML Ain't Markup Language, objetos portables y archivos de texto plano. Las demás extensiones de archivo fallan en la planificación a menos que `L10N.md` declare el comando `validation`. Esto evita tratar silenciosamente un formato estructurado propietario como texto sin restricciones.

El comando de validación se ejecuta después de que el candidato se haya escrito temporalmente a su ruta de destino real. Puede invocar el parser, compilador o comando de compilación nativo del repositorio. Glossia restaura el destino anterior tras cada intento de validación y solo escribe al candidato aceptado después.

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

## Idiomas de destino

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
| `{locale}` or `{lang}` | Código de localización de destino. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre de archivo de origen sin su extensión. |
| `{ext}` | Extensión de archivo de origen sin el punto inicial. |

## Reglas múltiples

Utilice `translate` cuando diferentes grupos de contenido necesiten destinos o comprobaciones diferentes:

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

Glossia lee los archivos `L10N.md` desde la raíz del repositorio hacia el archivo de origen:

- Los ajustes de progenitor proporcionan valores predeterminados.
- Un archivo más profundo sobrescribe los campos de su directorio.
- El contexto de Markdown se acumula de progenitor a hijo.
- La orientación específica de la localización y un manejador de modelo específico de la localización pueden residir en `L10N/<locale>.md`.

Esto permite que un repositorio mantenga una orientación de voz general en la raíz, mientras coloca la orientación del área de producto o específica del idioma cerca del contenido que afecta.