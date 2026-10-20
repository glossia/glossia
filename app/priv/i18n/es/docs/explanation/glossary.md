%{
  title: "Glosario",
  summary:
    "Cómo Glossia mantiene las traducciones aprobadas consistentes en cada idioma y archivo.",
  category: "explicación",
  section: "translation",
  order: 5
}
---

Un glosario es un conjunto curado de términos que tus traducciones deben renderizar de la misma manera cada vez. "Commit" en el sentido de control de versiones permanece `commit` en español, se convierte en `提交` en chino simplificado, y `コミット` en japonés. Una decisión por idioma, obligatoria en todas partes.

## Dos lugares donde puede vivir un glosario

Glossia busca entradas de glosario en dos lugares y las combina en el momento de la traducción:

- **Tu repositorio**, en los archivos que ya usas para configuraciones de traducción. `L10N.md` declara los términos, y las `L10N/<locale>.md` de cada idioma declaran sus traducciones. Este es el glosario autoritativo del desarrollador: los cambios atraviesan solicitudes de extracción, los revisores de cada idioma poseen su propio archivo, y los archivos anidados pueden refinarlo para parte del repositorio.
- **Tu cuenta de Glossia**, gestionado a través del panel de control alojado. Este es el glosario autoritativo del lingüista: los revisores y colaboradores de localización agregan o refinan entradas sin tocar el código, a través del panel de control, la [REST API](/docs/reference/apis) o el [MCP server](/docs/reference/mcp). Se aplica a cada repositorio que la cuenta traduce.

Ambos lugares son útiles, y ninguno reemplaza al otro.

## Cuándo usar cada uno

Define un término en **tu cuenta de Glossia** cuando:

- **Se aplica a más de un repositorio.** Los nombres de productos, términos de la marca y el vocabulario empresarial se definen una vez y se usan en todas partes.
- **Las personas que deciden no trabajan en el repositorio.** Los lingüistas, revisores y colaboradores externos pueden refinar el glosario incluso cuando el repositorio es de código cerrado o no tienen acceso de escritura a él.
- **Quieres corregir un término sin un cambio de código.** Una traducción corregida se aplica en la siguiente ejecución, sin un pull request contra la base de código.
- **Los cambios necesitan revisión e historial.** Cada edición crea una nueva versión con una nota de cambio, los colaboradores pueden proponer cambios como sugerencias para que alguien las apruebe, y las versiones anteriores permanecen disponibles.
- **Otras herramientas lo necesitan.** Los agentes y las integraciones pueden leer el glosario a través de REST API y el MCP server, por ejemplo, para escribir nuevo contenido que ya uses términos aprobados.

Define un término en **tu repositorio** cuando:

- **Pertenece a esta base de código.** Un término cuyo significado es específico de un proyecto, como "commit" significando la acción de control de versiones, está junto al código que lo usa.
- **Debería cambiar junto con el texto fuente.** El término y el contenido que lo introducen aterrizan en la misma solicitud de extracción y se revisan juntos.
- **Solo parte del repositorio lo necesita.** Un `L10N.md` o `L10N/<locale>.md` anidados pueden agregar o sobrescribir entradas para un directorio, como las páginas de marketing.
- **Debe sobrescribir el glosario de la cuenta.** Una entrada del repositorio gana sobre una entrada de cuenta por el mismo término, para los idiomas que traduce.

## Cómo se combinan

Para cada archivo e idioma de destino, Glossia resuelve los dos glosarios en un conjunto efectivo:

1. Comienza con las entradas del glosario de la cuenta para el idioma de destino.
2. Superpone las entradas del repositorio para ese idioma: los términos de la cadena de `L10N.md` del archivo que tienen una traducción en su cadena de `L10N/<locale>.md`. Cuando una entrada del repositorio tiene el mismo término fuente que una entrada de cuenta, la entrada del repositorio gana.
3. Si un término del repositorio no tiene traducción para un idioma, la entrada de la cuenta para ese idioma sigue aplicándose. El repositorio nunca bloquea un idioma que no tradujo.

La fusión ocurre **por idioma de destino**, no por entrada. Una traducción en español de "commit" en `L10N/es.md` reemplaza la entrada en español de la cuenta para "commit", pero no toca la entrada en japonés de la cuenta para el mismo término. Los revisores pueden ver qué entradas de la cuenta se reemplazaron: el resumen de la sesión de traducción muestra cuántas fueron sobrescritas, y el archivo de bloqueo de cada archivo las lista bajo `glossary.shadowed`.

## Cuando el glosario cambia, los archivos se vuelven a traducir

Cuando editas una entrada del glosario, Glossia solo vuelve a traducir los archivos cuya *glosario efectivo cambió*. Si el texto fuente de un archivo no contiene coincidencias para el término editado, sus traducciones permanecen intactas. Si un archivo usa el término, su próxima pasada de traducción incluye la instrucción actualizada.

El mismo principio se aplica en reversa: agregar un término que solo se usa en un subconjunto de archivos no fuerza una ejecución completa.

## Qué no es un glosario

- No es un diccionario de traducción automática. El modelo de Glossia lee el contexto circundante y puede traducir un término de manera diferente si la oración lo exige. El glosario es una guía, no una sustitución.
- No es la guía de estilo completa. Voz, tono, formalidad y audiencia viven en la configuración de Voz de tu cuenta y en `L10N.md`. El glosario es solo para términos individuales y sus traducciones aprobadas.
- No es silencioso. Cada término aplicado se registra en el archivo de bloqueo del archivo para que un revisor pueda rastrear exactamente qué entradas del glosario alcanzaron el modelo.

## Relacionado

- Agrega tus primeros términos: [Define un glosario](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referencia de glosario](/docs/reference/glossary).
- Los demás campos de `L10N.md`: [Referencia de L10N.md](/docs/reference/l10n-md).
