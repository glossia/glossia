%{
  title: "GLOSSIA.md",
  summary: "Referencia de la configuración y el contexto de traducción del repositorio.",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md` indica a Glossia qué archivos debe traducir, dónde deben guardarse los archivos traducidos, qué idiomas debe utilizar como destino y qué contexto debe orientar el resultado. Un repositorio puede tener un archivo raíz y archivos adicionales con ámbitos específicos en subdirectorios.

## Estructura

Cada archivo tiene dos partes:

1. Cabecera de [YAML Ain't Markup Language](https://yaml.org/) entre marcadores `---`.
2. Contenido Markdown después de la cabecera con contexto sobre el producto, la audiencia, la voz o el dominio.

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

Las credenciales del proveedor deben guardarse en la configuración de la cuenta, nunca en `GLOSSIA.md`. El valor opcional `model` es un identificador de modelo de la cuenta.

## Campos de la cabecera

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `source_language` | cadena | no | Configuración regional de origen para este ámbito. El valor predeterminado es `en`. |
| `model` | cadena | no | Identificador de modelo de la cuenta. Glossia utiliza el valor predeterminado de la cuenta cuando se omite y notifica un error cuando un identificador explícito no existe. |
| `sources` | mapa o lista | para una regla de nivel superior | Patrones de archivos de origen. Los valores del mapa pueden definir plantillas de salida. |
| `targets` | mapa o lista | cuando se configuran fuentes | Códigos de configuración regional de destino. Un mapa puede asociar un código de configuración regional con el nombre de un idioma. |
| `output` | cadena | cuando ninguna asignación de origen ni `target_path` proporciona un destino | Plantilla del archivo de salida. |
| `target_path` | cadena | cuando ninguna asignación de origen ni `output` proporciona un destino | Plantilla del directorio base para los archivos traducidos. |
| `translate` | lista | no | Varias reglas de traducción, cada una con sus propias fuentes y modificaciones opcionales. |
| `exclude` | lista | no | Patrones de archivos que se deben omitir. |
| `preserve` | lista | no | Tipos de contenido que deben permanecer sin cambios, como marcadores de posición o localizadores uniformes de recursos. |
| `frontmatter` | cadena | no | `preserve` de forma predeterminada, o `translate`. |
| `prompt` | cadena | no | Indicaciones adicionales para este ámbito o regla. |
| `validation` | lista | para extensiones de archivo sin un adaptador integrado | Un comando de validación seguido de sus argumentos. El comando recibe el archivo candidato en su ruta de destino real y debe devolver un estado distinto de cero cuando el archivo no sea válido. |
| `check_cmd` | cadena | no | Un comando de comprobación disponible para el flujo de trabajo de traducción. |
| `check_cmds` | mapa | no | Comandos de comprobación con nombre disponibles para el flujo de trabajo de traducción. |
| `retries` | entero | no | Número de reintentos después de una comprobación fallida. El valor predeterminado es `2`. |
| `locale` | cadena | no | Configuración regional asociada a un archivo de contexto específico de una configuración regional. |

Los campos desconocidos de la cabecera se ignoran.

## Formatos de archivo

Glossia incluye compatibilidad integrada con archivos Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objetos portables y texto sin formato. La planificación falla para otras extensiones de archivo, a menos que el `GLOSSIA.md` aplicable declare un comando `validation`. Esto evita que un formato estructurado propietario se trate de forma inadvertida como texto sin restricciones.

El comando de validación se ejecuta después de escribir temporalmente el archivo candidato en su ruta de destino real. Puede invocar el analizador, compilador o comando de compilación nativo del repositorio. Glossia restaura el destino anterior después de cada intento de validación y solo escribe posteriormente el archivo candidato aceptado.

## Asignaciones de origen

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

## Idiomas de destino

Una lista utiliza cada código de configuración regional como identificador de idioma:

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
| `{locale}` o `{lang}` | Código de configuración regional de destino. |
| `{relpath}` | Ruta de origen relativa al patrón coincidente. |
| `{basename}` | Nombre del archivo de origen sin su extensión. |
| `{ext}` | Extensión del archivo de origen sin el punto inicial. |

## Varias reglas

Utilice `translate` cuando distintos grupos de contenido necesiten destinos o comprobaciones diferentes:

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

Los valores de las reglas sustituyen los valores heredados del archivo que las contiene.

## Contexto por ámbito

Glossia lee los archivos `GLOSSIA.md` desde la raíz del repositorio hasta el archivo de origen:

- La configuración principal proporciona los valores predeterminados.
- Un archivo ubicado en un nivel más profundo sustituye los campos correspondientes de su directorio.
- El contexto de Markdown se acumula de los niveles superiores a los inferiores.
- Las directrices específicas de la configuración regional y un identificador de modelo específico de esta pueden residir en `GLOSSIA/<locale>.md`.

Esto permite que un repositorio mantenga directrices generales de voz en la raíz y coloque las directrices específicas de un área del producto o de un idioma cerca del contenido al que afectan.