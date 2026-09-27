%{
  title: "Glosario",
  summary:
    "Cómo Glossia mantiene las traducciones aprobadas consistentes en cada idioma y archivo.",
  category: "explicación",
  section: "traducción",
  order: 5
}
---
Un glosario es un conjunto curado de términos que tus traducciones deben renderizar de la misma manera siempre. \\"Commit\\" en el sentido de control de versiones permanece `commit` en español, se convierte en `提交` en chino simplificado, y `コミット` en japonés. Una decisión por idioma, aplicada en todas partes.

## Dos lugares donde puede residir un glosario

Glossia busca entradas de glosario en dos lugares y las une durante la traducción:

- **Tu repositorio**, en los archivos que ya usas para la configuración de traducción. `L10N.md` declara los términos, y los de cada idioma `L10N/<locale>.md` declaran sus traducciones. Este es el glosario autoritativo del desarrollador: los cambios viajan a través de pull requests, los revisores de cada idioma poseen su propio archivo, y los archivos anidados pueden refinarlo para una parte del repositorio.
- **El servidor**, almacenado con tu cuenta. Este es el glosario autoritativo del lingüista: los revisores y contribuyentes de localización añaden o refinan entradas sin tocar el código, a través del panel de control, el [REST API](/docs/reference/apis), o el [servidor MCP](/docs/reference/mcp). Se aplica a cada repositorio que la cuenta traduce.

Ambos lugares son útiles y ninguno reemplaza al otro.

## Cuándo usar cuál

Definir un término en **el servidor** cuando:

- **Aplica a más de un repositorio.** Nombres de productos, términos de marca y vocabulario corporativo se definen una vez y se usan en todas partes.
- **Quienes deciden esto no trabajan en el repositorio.** Lingüistas, revisores y colaboradores externos pueden refinar el glosario incluso cuando el repositorio es de código cerrado o no tienen acceso de escritura.
- **Quiere corregir un término sin modificar el código.** Una traducción corregida se aplica en la siguiente ejecución, sin pull request contra la base de código.
- **Los cambios requieren revisión e historial.** Cada edición crea una nueva versión con una nota de cambio; los colaboradores pueden proponer cambios como sugerencias para que alguien las apruebe, y las versiones anteriores permanecen disponibles.
- **Otras herramientas lo necesitan.** Los agentes y las integraciones pueden leer el glosario a través de la API REST y del servidor MCP, por ejemplo, para crear contenido nuevo que ya utilice los términos aprobados.

Defina un término en **tu repositorio** cuando:

- **Pertenece a este código base.** Un término cuyo significado es específico para un proyecto, como "commit" que significa la acción de control de versiones, se coloca junto al código que lo utiliza.
- **Debe cambiar junto con el texto de origen.** El término y el texto que lo introducen llegan en la misma solicitud de extracción y se revisan juntos.
- **Solo una parte del repositorio lo necesita.** Una anidada `L10N.md` o `L10N/<locale>.md` puede agregar o sobrescribir entradas para un directorio, como las páginas de marketing.
- **Debe sobrescribir al servidor.** Una entrada del repositorio tiene prioridad sobre una entrada del servidor para el mismo término, para los idiomas que traduce.

## Cómo se combinan

Para cada archivo e idioma objetivo, Glossia resuelve los dos glosarios en un conjunto efectivo:

1. Comience con las entradas del glosario del servidor para el idioma objetivo.
2. Sobrescriba las entradas del repositorio para ese idioma: los términos del archivo del `L10N.md` cadenas que tienen una traducción en su `L10N/<locale>.md` cadena. Cuando una entrada del repositorio tiene el mismo término fuente que una entrada del servidor, la entrada del repositorio prevalece.
3. Si un término del repositorio no tiene traducción para un idioma, la entrada del servidor para ese idioma sigue aplicándose. El repositorio nunca bloquea un idioma que no haya traducido.

La fusión ocurre **por idioma objetivo**, no por entrada. Una traducción en español de "commit" en `L10N/es.md` reemplaza la entrada en español del servidor para "commit", pero no afecta la entrada en japonés del servidor para el mismo término. Los revisores pueden ver cuáles entradas del servidor fueron reemplazadas: el resumen de la sesión de traducción muestra cuántas fueron sobrescritas, y el archivo de bloqueo de cada archivo las enumera bajo `glossary.shadowed`.

## Cuando el glosario cambia, los archivos se retraducen

Cuando editas una entrada de glosario, Glossia solo vuelve a traducir los archivos cuyos *glosario efectivo ha cambiado.*. Si el texto fuente del archivo no contiene coincidencias para el término editado, sus traducciones permanecen intactas. Si el archivo usa el término, su siguiente paso de traducción incluye la instrucción actualizada.

El mismo principio se aplica en sentido inverso: agregar un término usado solo por un subconjunto de archivos no obliga a una re-ejecución completa.

## Qué no es un glosario

- No es un diccionario de traducción automática. El modelo de Glossia lee el contexto circundante y puede renderizar un término de forma diferente si la oración lo requiere. El glosario es una guía, no una sustitución.
- No es toda la guía de estilo. La voz, el tono, la formalidad y el público residen en la configuración de voz de su cuenta y en. `L10N.md`. El glosario es solo para términos individuales y sus traducciones aprobadas.
- No es silencioso. Cada término aplicado se registra en el archivo de bloqueo para que un revisor pueda rastrear exactamente qué entradas del glosario alcanzaron el modelo.

## Relacionado

- Añade tus primeros términos: [Define un glosario](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referencia del glosario](/docs/reference/glossary).
- Los otros `L10N.md` campos: [Referencia de L10N.md](/docs/reference/l10n-md).