%{
  title: "Glosario",
  summary:
    "Cómo Glossia mantiene las traducciones aprobadas consistentes en todos los idiomas y archivos.",
  category: "explicación",
  section: "translation",
  order: 5
}
---

Un glosario es un conjunto curado de términos que tus traducciones deben representar de la misma manera cada vez. "Commit" en el sentido de control de versiones permanece `commit` en español, se convierte en `提交` en chino simplificado y `コミット` en japonés. Una decisión por idioma, aplicada en todas partes.

## Un glosario puede habitar en dos lugares

Glossia busca raspas doslugares para entradas de glosario y las fusiona durante la traducción:

- **Tu repositorio**, en los archivos que ya usas para la configuración de traducción. `L10N.md` declara los términos, y cada lenguaje `L10N/<locale>.md` declara sus traducciones. Este es el glosario de autoridad del desarrollador: los cambios viajan a través de las solicitudes de extracción, los revisores de cada idioma poseen su propio archivo, y los archivos anidados pueden refinarse para parte del repositorio.
- **Tu cuenta de Glossia**, gestionada a través del panel de control alojado. Este es el glosario de autoridad del lingüista: los revisores y colaboradores de localización agregan o refinan entradas sin tocar el código, a través del panel de control, la [API REST](/docs/reference/apis) o el [servidor MCP](/docs/reference/mcp). Se aplica a todos los repositorios que la cuenta traduce.

Ambos lugares son útiles, y ninguno reemplaza al otro.

## Cuándo utilizar cuál

Define un término en **tu cuenta de Glossia** cuando:

- **Aplica a más de un repositorio.** Los nombres de productos, términos de marca y vocabulario corporativo se definen una vez y se usan en todas partes.
- **Las personas que deciden esto no trabajan en el repositorio.** Los lingüistas, revisores y contribuyentes externos pueden refinar el glosario aunque el repositorio sea de software cerrado o no tengan acceso de escritura a él.
- **Quieres corregir un término sin cambiar el código.** Una corrección de traducción se aplica en la ejecución siguiente, sin una solicitud de extracción contra la base de código.
- **Los cambios requieren revisión e historial.** Cada edición crea una nueva versión con una nota de cambio; los contribuyentes pueden proponer cambios como sugerencias para alguien que apruebe y las versiones anteriores permanecen disponibles.
- **Otras herramientas lo necesitan.** Los agentes e integraciones pueden leer el glosario a través de la API REST y el servidor MCP, por ejemplo para escribir contenido nuevo que ya utilice los términos aprobados.

Define un término en **tu repositorio** cuando:

- **Pertenece a este repositorio.** Un término cuyo significado es específico de un proyecto, como "commit" significando la acción de control de versiones, se sitúa junto al código que lo usa.
- **Debe cambiar junto con el texto fuente.** El término y el texto que lo introdujo aterrizan en la misma solicitud de extracción y se revisan juntos.
- **Solo parte del repositorio lo necesita.** Un `L10N.md` o `L10N/<locale>.md` puede agregar o anular entradas para una carpeta, como las páginas de marketing.
- **Debe sobrescribir el glosario de la cuenta.** Una entrada del repositorio gana a una entrada de la cuenta para el mismo término, para los idiomas que traduce.

## Cómo se combinan

Para cada archivo y lenguaje de destino, Glossia resuelve los dos glosarios en un conjunto efectivo:

1. Comienza con las entradas del glosario de la cuenta para el lenguaje de destino.
2. Sobreponer las entradas del repositorio para ese lenguaje: los términos de la `L10N.md` cadena del archivo que tienen una traducción en su cadena `L10N/<locale>.md`. Cuando una entrada del repositorio tiene el mismo término fuente que una entrada de la cuenta, la entrada del repositorio prevalece.
3. Si un término del repositorio no tiene una traducción para un idioma, la entrada de la cuenta para ese idioma sigue aplicándose. El repositorio nunca bloquea un idioma que no ha traducido.

La fusión ocurre **por lenguaje de destino**, no por entrada. Una traducción española de "commit" en `L10N/es.md` reemplaza la entrada de la cuenta de "commit", pero no afecta la entrada de la cuenta de "commit" en japonés. Los revisores pueden ver qué entradas de la cuenta se reemplazaron: el resumen de la sesión de traducción muestra cuántas se sobrescribieron, y el archivo de bloqueo de cada archivo los enumera bajo `glossary.shadowed`.

## Cuando el glosario cambia, los archivos se vuelven a traducir

Cuando editas una entrada del glosario, Glossia solo vuelve a traducir los archivos cuyo *glosario efectivo cambió*. Si el texto fuente de un archivo no contiene coincidencias para el término editado, sus traducciones permanecen sin tocarse. Si un archivo usa el término, su próxima pasada de traducción incluye la instrucción actualizada.

El mismo principio se aplica en reversa: agregar un término usado solo por un subconjunto de archivos no fuerza una nueva ejecución completa.

## Qué no es un glosario

- No es un diccionario de traducción automática. El modelo de Glossia lee el contexto circundante y puede representar un término de manera diferente si la oración lo exige. El glosario es orientación, no sustitución.
- No es la guía de estilos completa. La voz, el tono, la formalidad y la audiencia viven en la configuración de Voz de tu cuenta y en `L10N.md`. El glosario es solo para términos individuales y sus traducciones aprobadas.
- No es silencioso. Cada término aplicado se registra en el archivo de bloqueo del archivo para que un revisor pueda rastrear exactamente qué entradas del glosario alcanzaron el modelo.

## Relacionadas

- Agrega tus primeros términos: [Define un glosario](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referencia al glosario](/docs/reference/glossary).
- Los otros `L10N.md` campos: [L10N.md referencia](/docs/reference/l10n-md).
