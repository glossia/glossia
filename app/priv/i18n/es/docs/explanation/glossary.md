%{
  title: "Glosario",
  summary:
    "Cómo Glossia mantiene las traducciones aprobadas consistentes en cada idioma y cada archivo.",
  category: "explicación",
  section: "translation",
  order: 5
}
---
Un glosario es un conjunto curado de términos que tus traducciones deben mostrar de la misma manera cada vez. "Commit" en el sentido de control de versiones se mantiene `commit` en español, se convierte en `提交` en chino simplificado, y `コミット` en japonés. Una decisión por idioma, aplicada en todas partes.

## Dos lugares donde puede residir un glosario

Glossia busca entradas de glosario en dos lugares y las fusiona en el momento de la traducción:

- **Tu repositorio**, en los archivos que ya usas para la configuración de traducción. `L10N.md` declara los términos, y cada idioma `L10N/<locale>.md` declarar sus traducciones. Este es el glosario de autoridad del desarrollador: los cambios viajan a través de solicitudes de extracción, cada idioma tiene revisores que poseen su propio archivo, y los archivos anidados pueden refinarlo para una parte del repositorio.
- **Tu cuenta de Glossia**, gestionado a través del panel de control alojado. Este es el glosario de autoridad del lingüista: revisores y contribuyentes de la localización agregan o refinan entradas sin tocar el código, a través del panel de control, [REST API](/docs/reference/apis), o el [MCP server](/docs/reference/mcp). Se aplica a cada repositorio que traduce la cuenta.

Ambos lugares son útiles y ninguno sustituye al otro.

## Cuándo usar cuál

Definir un término en **tu cuenta de Glossia** cuándo:

- **Se aplica a más de un repositorio.** Los nombres de productos, los términos de marca y el vocabulario corporativo se definen una vez y se utilizan en todas partes.
- **Las personas que deciden esto no trabajan en el repositorio.** Los lingüistas, revisores y contribuyentes externos pueden refinar el glosario incluso cuando el repositorio es de código cerrado o no tienen acceso de escritura a él.
- **Quieres corregir un término sin cambiar el código.** Una traducción corregida se aplica en la siguiente ejecución, sin pull request contra la base de código.
- **Los cambios requieren revisión e historial.** Cada edición crea una nueva versión con una nota de cambio, los contribuyentes pueden proponer cambios como sugerencias para su aprobación y las versiones anteriores se mantienen disponibles.
- **Otras herramientas lo necesitan.** Los agentes e integraciones pueden leer el glosario a través de la API REST y el servidor MCP, por ejemplo para generar nuevo contenido que ya utiliza los términos aprobados.

Definir un término en **tu repositorio** cuando:

- **Pertenece a esta base de código.** Un término cuyo significado es específico de un proyecto, como "commit" que significa la acción de control de versiones, se encuentra junto al código que lo utiliza.
- **Debe cambiar junto con el texto de origen.** El término y el texto que lo introduce llegan al mismo pull request y son revisados juntos.
- **Solo parte del repositorio lo necesita.** Un anidado `L10N.md` o `L10N/<locale>.md` puede agregar o sobrescribir entradas para un directorio, como las páginas de marketing.
- **Debe sobrescribir el glosario de la cuenta.** Una entrada del repositorio tiene prioridad sobre una entrada de la cuenta para el mismo término, para los idiomas que traduce.

## Cómo se combinan

Para cada archivo e idioma objetivo, Glossia resuelve los dos glosarios en un conjunto efectivo:

1. Comience con las entradas del glosario de la cuenta para el idioma objetivo.
2. Superponga las entradas del repositorio para ese idioma: los términos del archivo `L10N.md` cadena que tiene una traducción en su `L10N/<locale>.md` cadena. Cuando una entrada de repositorio tiene el mismo término fuente que una entrada de cuenta, la entrada del repositorio prevalece.
3. Si un término del repositorio no tiene traducción para un idioma, la entrada de cuenta para ese idioma sigue aplicándose. El repositorio nunca bloquea un idioma que no haya traducido.

La fusión ocurre **por idioma objetivo**, no por entrada. Una traducción de "commit" en `L10N/es.md` reemplaza la entrada en español de la cuenta para "commit", pero no afecta la entrada japonesa de la cuenta para el mismo término. Los revisores pueden ver qué entradas de cuenta se reemplazaron: el resumen de la sesion de traduccion muestra cuántas fueron sobrescritas, y el archivo de bloqueo de cada archivo los enumera bajo `glossary.shadowed`.

## Cuando el glosario cambia, los archivos se retraducen

Cuando edita una entrada de glosario, Glossia solo vuelve a traducir los archivos cuyo *glosario efectivo cambió*. Si el texto de origen de un archivo no contiene coincidencias para el término editado, sus traducciones permanecen intactas. Si un archivo utiliza el término, su próxima pasada de traducción incluye la instrucción actualizada.

El mismo principio se aplica en sentido inverso: añadir un término utilizado solo por un subconjunto de archivos no fuerza una re-ejecución completa.

## Qué no es un glosario

- No es un diccionario de traducción automática. El modelo de Glossia lee el contexto circundante y puede traducir un término de forma diferente si la oración lo exige. El glosario es una guía, no una sustitución.
- No es toda la guía de estilo. Voz, tono, formalidad y audiencia viven en la configuración de Voz de tu cuenta y en `L10N.md`. El glosario es solo para términos individuales y sus traducciones aprobadas.
- No es silencioso. Cada término aplicado se registra en el archivo de bloqueo para que un revisor pueda rastrear exactamente qué entradas del glosario llegaron al modelo.

## Relacionado

- Añade tus primeros términos: [Define un glosario](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referencia del glosario](/docs/reference/glossary).
- Los otros `L10N.md` campos: [L10N.md de referencia](/docs/reference/l10n-md).