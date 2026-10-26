%{
  title: "Glosario",
  summary:
    "Cómo Glossia mantiene las traducciones aprobadas consistentes en cada idioma y cada archivo.",
  category: "explicación",
  section: "translation",
  order: 5
}
---

Un glosario es un conjunto curado de términos que tus traducciones deben renderizar de la misma manera cada vez. "Commit" en el sentido de control de versiones permanece `commit` en español, se convierte en `提交` en chino simplificado y en `コミット` en japonés. Una decisión por idioma, aplicada en todas partes.

## Dos lugares donde puede vivir un glosario

Glossia busca entradas de glosario en dos lugares y las fusiona en el momento de la traducción:

- **Tu repositorio**, en los archivos que ya usas para la configuración de traducción. `L10N.md` declara los términos, y el `L10N/<locale>.md` de cada idioma declara sus traducciones. Este es el glosario de autoridad del desarrollador: los cambios viajan a través de solicitudes de extracción, los revisores de cada idioma poseen su propio archivo, y los archivos anidados pueden refinarse para parte del repositorio.
- **Tu cuenta de Glossia**, gestionada a través del panel de control alojado. Este es el glosario de autoridad del lingüista: revisores y contribuyentes de localización añaden o refinan entradas sin tocar el código, a través del panel de control, el [REST API](/docs/reference/apis) o el [MCP server](/docs/reference/mcp). Se aplica a cada repositorio que la cuenta traduce.

Ambos lugares son útiles, y ninguno reemplaza al otro.

## Cuándo usar cuál

Define un término en **tu cuenta de Glossia** cuando:

- **Se aplica a más de un repositorio.** Nombres de productos, términos de marca y vocabulario empresarial se definen una vez y se usan en todas partes.
- **Las personas que lo deciden no trabajan en el repositorio.** Lingüistas, revisores y contribuyentes externos pueden refinar el glosario incluso si el repositorio es de código cerrado o no tienen acceso de escritura a él.
- **Quieres corregir un término sin cambiar el código.** Una traducción corregida se aplica en la siguiente ejecución, sin ninguna solicitud de extracción contra el repositorio.
- **Los cambios requieren revisión e historial.** Cada edición crea una nueva versión con un registro de cambio, los contribuyentes pueden proponer cambios como sugerencias para que alguien las apruebe, y las versiones anteriores permanecen disponibles.
- **Otras herramientas lo necesitan.** Los agentes e integraciones pueden leer el glosario a través del REST API y del MCP server, por ejemplo para escribir nuevo contenido que ya usa los términos aprobados.

Define un término en **tu repositorio** cuando:

- **Pertenece a esta base de código.** Un término cuyo significado es específico para un proyecto, como "commit" que significa la acción de control de versiones, está junto al código que lo usa.
- **Debe cambiar junto con el texto fuente.** El término y el texto que lo introdujo aterrizan en la misma solicitud de extracción y se revisan juntos.
- **Solo parte del repositorio lo necesita.** Un `L10N.md` anidado o `L10N/<locale>.md` puede agregar o sobrescribir entradas para un directorio, como las páginas de marketing.
- **Debe sobrescribir el glosario de la cuenta.** Una entrada de repositorio gana sobre una entrada de cuenta para el mismo término, para los idiomas que traduce.

## Cómo se combinan

Para cada archivo e idioma objetivo, Glossia resuelve los dos glosarios en un conjunto efectivo:

1. Comienza con las entradas del glosario de la cuenta para el idioma objetivo.
2. Superpone las entradas del repositorio para ese idioma: los términos de la cadena `L10N.md` del archivo que tienen una traducción en su cadena `L10N/<locale>.md`. Cuando una entrada del repositorio tiene el mismo término fuente que una entrada de cuenta, la entrada del repositorio gana.
3. Si un término del repositorio no tiene traducción para un idioma, la entrada de la cuenta para ese idioma sigue aplicándose. El repositorio nunca bloquea un idioma que no tradujo.

La unión sucede **por idioma objetivo**, no por entrada. Una versión en español de "commit" en `L10N/es.md` reemplaza la entrada en español de la cuenta para "commit", pero no afecta la entrada japonesa de la cuenta para el mismo término. Los revisores pueden ver qué entradas de la cuenta fueron reemplazadas: el resumen de la sesión de traducción muestra cuántas fueron sobrescritas, y el archivo de bloqueo de cada archivo las lista bajo `glossary.shadowed`.

## Cuando el glosario cambia, los archivos vuelven a traducirse

Cuando editas una entrada del glosario, Glossia solo vuelve a traducir los archivos de los que el *glosario efectivo cambió*. Si el texto fuente de un archivo no contiene coincidencias para el término editado, sus traducciones permanecen sin cambios. Si un archivo usa el término, su siguiente paso de traducción incluye la instrucción actualizada.

El mismo principio se aplica a la inversa: agregar un término usado solo por un subconjunto de archivos no fuerza una reejecución completa.

## Qué no es un glosario

- No es un diccionario de traducción automática. El modelo de Glossia lee el contexto circundante y puede renderizar un término de manera diferente si la oración lo exige. El glosario es una guía, no una sustitución.
- No es toda la guía de estilo. La voz, el tono, la formalidad y la audiencia viven en la configuración de Voz de tu cuenta y en `L10N.md`. El glosario es solo para términos individuales y sus traducciones aprobadas.
- No es silencioso. Cada término aplicado se registra en el archivo de bloqueo del archivo para que un revisor pueda rastrear exactamente qué entradas del glosario llegaron al modelo.

## Relacionado

- Añade tus primeros términos: [Define un glosario](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referencia del glosario](/docs/reference/glossary).
- Los otros `L10N.md` campos: [L10N.md referencia](/docs/reference/l10n-md).
