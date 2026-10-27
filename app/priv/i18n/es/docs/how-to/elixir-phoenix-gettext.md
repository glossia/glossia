%{
  title: "Elixir y Phoenix (Gettext)",
  summary:
    "Configurar la traducción de Gettext, preservar los metadatos del catálogo y reducir los conflictos de fusión.",
  category: "Tutorial",
  section: "ecosystems",
  order: 1
}
---

Usa esta guía para conectar una aplicación existente de Elixir o Phoenix utilizando [Gettext](https://hexdocs.pm/gettext/) en Glossia y mantener sus catálogos compatibles con la fusión. Ejecuta los comandos de Mix desde el directorio que contiene `mix.exs`.

## 1. Configura la extracción determinista

Agrega estas opciones a tu `project/0` existente en `mix.exs`:

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

Mantén cualquier otra opción de Gettext que ya utilices. `sort_by_msgid: :case_sensitive` es compatible con la versión de Gettext que usa Glossia; revisa las [opciones de extracción](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) de tu dependencia cuando apliques esto a otro proyecto.

Vuelve a generar las plantillas y los archivos de localización:

```sh
mix gettext.extract --merge
```

Revisa y confirma esta normalización única por separado de los cambios de redacción. El orden de los mensajes debe cambiar, no las traducciones existentes. Coordina esta normalización con las pull requests abiertas para que sus catálogos puedan actualizarse al mismo orden.

La clasificación coloca los nuevos mensajes independientes en sus posiciones canónicas en lugar de agregar cada adición al final del archivo. Omitir números de línea de referencia evita diferencias no relacionadas cuando se mueve el código; las referencias a archivos fuente se mantienen. Estas opciones reducen los conflictos, pero no pueden eliminar conflictos sobre el mismo mensaje o garantizar que cada par de inserciones se fusiona automáticamente.

## 2. Traduce las plantillas, no el código fuente de la aplicación

Crea un `L10N.md` junto a `mix.exs`, o añade las siguientes asignaciones a tu configuración existente:

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

Incluye solo los dominios presentes en tu aplicación. Añade una asignación para cada dominio adicional, como `dashboard_projects.pot`. El destino es un directorio: el gestor de objetos portátiles escribe `default.po`, `errors.po` y otros nombres de archivo de dominio coincidentes allí.

Usa las plantillas `.pot` como fuentes y los archivos `.po` de localización como salidas. No uses una localización traducida como fuente para otras localizaciones. Consulta la [referencia L10N.md](/docs/reference/l10n-md) para configuraciones anidadas y el [tutorial de inicio rápido](/docs/tutorials/getting-started) para conectar el repositorio con Glossia.

## 3. Extrae antes de publicar cambios de fuente

Cuando una pull request modifica una llamada a `gettext`, `dgettext`, o `ngettext`:

1. Actualiza el código de la aplicación.
2. Ejecuta `mix gettext.extract --merge`.
3. Revisa las diferencias de la plantilla y de la localización junto con el cambio de código.
4. Confirma los cambios generados antes de integrar la pull request.

Después de integrar los cambios de fuente, Glossia traduce las plantillas actualizadas y publica los cambios de localización en una pull request de traducción. Revisa esas traducciones a través del proceso normal del repositorio.

Mantén `msgid` y `msgctxt` como identificadores de fuente. Traduce los valores `msgstr`, incluidas las variantes plurales requeridas. Preserva los marcadores de posición de interpolación, encabezados de formato plural, referencias a fuente, comentarios del traductor y banderas. Una entrada `fuzzy` necesita revisión: no elimines la bandera solo para que una verificación pase, y no asumas que su traducción anterior es correcta para un mensaje cambiado.

## 4. Valida los cambios de catálogo en CI

Ejecuta:

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

La verificación de extracción detecta plantillas o archivos de localización que ya no coinciden con el código fuente de la aplicación. La compilación verifica que Gettext pueda compilar los catálogos. Ningún comando verifica la calidad lingüística o prueba que cada mensaje tenga una traducción revisada.

Si la extracción reporta archivos obsoletos, vuelve a generar localmente, revisa las diferencias y confírmalo. No saltés la verificación ni reescribas repetidamente las plantillas en el trabajador de traducción para ocultar una falta de coincidencia de fuente.

## 5. Resuelve conflictos de catálogo por identidad del mensaje

Cuando actualices una rama desde la rama principal:

1. Resuelve primero los conflictos del código fuente de la aplicación, preservando el texto de interfaz de usuario previsto.
2. Concilia las entradas de catálogo de ambas ramas usando su contexto e identidad de mensaje de fuente, incluidos los identificadores plurales cuando estén presentes. Preserva las traducciones existentes, comentarios, banderas y formas plurales; elimina los marcadores de conflicto y las entradas duplicadas antes de ejecutar el analizador.
3. Ejecuta `mix gettext.extract --merge` contra el código fuente resuelto.
4. Ejecuta las verificaciones de CI anteriores y revisa la diferencia de catálogo resultante.

No resuelvas un conflicto de catálogo aceptando ciegamente un lado completo, habilitando un controlador de unión de texto o concatenando los catálogos. Estos enfoques pueden perder traducciones válidas, duplicar identificadores o dejar un archivo inválido. Para conflictos recurrentes, añade una prueba de regresión que genere catálogos en dos ramas con nuevos mensajes diferentes y verifique que Git fusione tanto la plantilla como el catálogo traducido sin perder entradas.
