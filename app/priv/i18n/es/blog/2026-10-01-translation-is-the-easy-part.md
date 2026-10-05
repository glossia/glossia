%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre idiomas, la entrega de software y la confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---
Los idiomas son una gran y subestimada herramienta para la accesibilidad y para llevar productos tecnológicos a nuevos mercados. Cuando tu producto se dirige a comunidades cuya lengua principal no es el inglés, muestras que pensaste en ellas. Eso puede establecer una conexión muy profunda.

Lamentablemente, hacer que tu producto y marca hablen varios idiomas es algo que muchos equipos no pueden permitirse. A menudo se encuentran obligados a elegir dos de tres: **calidad, velocidad y costo**.

Si desean que las traducciones mantengan el ritmo de la entrega de software, pueden invertir en un equipo dedicado para mantener la calidad, pero eso conlleva un costo. O pueden apoyarse más en la traducción automática, avanzando rápido pero aceptando menor calidad. Si eligen calidad y bajo costo, confiando en la traducción humana sin un equipo dedicado, suelen sacrificar la velocidad. En el camino, acaban con sistemas intrincados que mueven traducciones entre sus repositorios y herramientas de terceros.

Desde [modelos de lenguaje grandes](https://en.wikipedia.org/wiki/Large_language_model) surgieron, mi esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/)y he hablado mucho sobre si podrían ayudarnos a dejar de hacer esos compromisos. Ella ama los idiomas y está profundamente integrada en la industria de la localización. Soy un constructor.

Tuist es mi trabajo principal. Cuando intenté traducir el producto y sus superficies de marketing, me encontré lidiando con soluciones convolucionadas. Ninguna de ellas se mantuvo al ritmo de nuestra velocidad de entrega y algunas provocaron conflictos que eran una pesadilla de resolver. He tenido ese momento de 'esto no se siente bien' muchas veces.

## Desde conversaciones hasta Glossia

Cada semana discutíamos nuevos patrones emergentes en las capacidades de los modelos de lenguaje. Vimos cómo crecía cada vez más el número de desarrolladores que construían sus propias cadenas de traducción. En el núcleo, estas cadenas impulsaban un modelo: importar el idioma de origen, traducir y luego seguir adelante.

Fue comprensible. Así es como operamos los constructores. Pero alguien más cercano a los idiomas y los procesos que los rodean podría ver cómo podría salir mal, desde inconsistencias en lo mejor hasta malintensiones en lo peor.

Los desarrolladores se mueven cada vez más rápido. No pueden ralentizarse para introducir un sistema cuyas flujos de trabajo subyacentes fueron diseñados mucho antes de Internet, llevados a un navegador y que aún luchan por satisfacer las necesidades de los equipos de software.

Así es como nació la idea de construir Glossia. Por un lado, apostaríamos por que los modelos mejoren en otros idiomas que el inglés y en la traducción. Por otro, construiríamos un sistema, inicialmente enfocado en contenido de software, que se sintiera plug-and-play. Alguna cosa que funcionara en segundo plano, ajustara tu velocidad de entrega y que te diera confianza de que la salida es correcta y lista para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo prompt. Algunos tokens, inglés que entra, traducción que sale, y ya está. Pero cuando te hablas con ellos, te das cuenta de que no saben si la salida es precisa, si captura la voz de su organización en ese idioma o si comunica el mensaje previsto eficazmente.

Tengo un pipeline similar en Tuist, traduciendo a idiomas como el japonés, y lo hago con una enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar que el formato sea correcto, pero eso no nos dice **si las palabras son las correctas**.

“Traducir es la parte fácil,” como dice mi esposa.

Nos embarcamos en descubrir cómo debería verse un buen sistema. Lo llamamos Glossia, y estamos empezando a abrirlo a personas y organizaciones interesadas en ayudarnos a iterarlo conjuntamente.

## Decidir qué traducir

El primer aspecto en el que nos centramos fue ayudar a las personas a decidir qué traducir. El costo de la traducción está disminuyendo y seguirá disminuyendo, pero nunca será cero. Las organizaciones todavía deberían ser selectivas sobre los idiomas en los que invierten.

A veces, esa elección surge directamente de una decisión empresarial. Otras veces, los equipos tienen una idea aproximada de sus comunidades y hacen una conjetura informada. Pensamos que había mucho que aprender de las personas que visitan sus sitios web o utilizan sus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones desde las que usan sus productos, pueden ofrecer una base mejor para esas decisiones.

La primera característica que lanzamos en Glossia fue la analítica. Añada una línea de código a su sitio web y la analítica comenzará a fluir hacia su cuenta. Presentamos esa información enfocada en la decisión que debe tomar: ¿en qué idiomas debería invertir próximamente?

A futuro, exploraremos cómo llevar las pruebas a la dimensión del idioma de un producto. Imagine medir qué tan a menudo los usuarios hacen clic en una llamada a la acción cuando una página utiliza diferentes voces en el mismo idioma. ¿No sería eso genial? Comparar variantes se ha centrado tradicionalmente en decisiones de producto y diseño, pero los idiomas también son parte del producto.

## De cero a traducción

Una vez que haya decidido traducir un proyecto, el siguiente paso es configurarlo. Como desarrollador, no me gustan los procesos con mucha fricción. Coincidimos en que ir de cero a la traducción debería ser idealmente un solo paso. Ese es el nivel de experiencia en el que nos esforzamos.

La configuración suele involucrar dos cosas. En primer lugar, extraer el contenido del repositorio para poder traducirlo, ya que a menudo comienza como cadenas de texto literales en el código. En segundo lugar, configurar el proyecto para seleccionar el contenido correcto basado en el idioma. Esto podría provenir del dispositivo del usuario o, en casos más sofisticados, una preferencia que hayan elegido.

Automatizar esto de manera fiable hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos para ello.

El proceso funciona así: conecte su repositorio de GitHub, seleccione los idiomas en los que desee traducir y, tras un tiempo, se abre una solicitud de extracción con los cambios. Una vez que la fusiona, las traducciones comenzarán. Eso es todoso.

Mantenemos las traducciones en el repositorio, junto a las comprobaciones de formato y otras validaciones que ya ejecutas como parte de [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). El pipeline de traducción devuelve los resultados de esas comprobaciones al agente de traducción. Esto elimina toda una clase de problemas donde una plataforma abre una solicitud de extracción y te deja lidiar con comprobaciones fallidas o conflictos de fusión.

Combinado con otros mecanismos para generar confianza, esto es lo que permite fusionar las traducciones automáticamente. Es el modelo en el que creemos. No tiene mucho valor pedirle a un desarrollador que verifique si una solicitud de extracción está verde y pulse un botón, especialmente cuando no pueden evaluar el idioma por sí mismos. Siempre hemos visto esa ceremonia extra como una señal de que el diseño podría ser mejor.

Creemos que el mejor sistema de traducción es aquel que funciona sin que tengas que pensar en ello.

## Traduciendo solo lo que cambió

El sistema de traducción merece una sección propia. Los tokens siguen sin ser gratuitos. Traducir todo el tiempo es lento, costoso y un desperdicio de recursos.

Para resolver eso, hemos construido un sistema de archivo de bloqueo que nos dice si algo necesita ser traducido. Llamamos a esto **traducción incremental**. La idea no es nueva: los sistemas de construcción la han utilizado durante mucho tiempo para evitar recompilar todo en cada construcción. Hemos adaptado esto a idiomas.

El sistema tiene en cuenta todo el contexto que afecta a una particular traducción. Parte de ese contexto reside en el repositorio. Otra parte reside en Glossia y abarca varios repositorios. Construimos un árbol de dependencias y utilizamos [árboles de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos indiquen si las entradas de una traducción han cambiado.

El archivo de bloqueo preserva ese árbol. Puede explicar por qué algo se envió para traducción, o por qué no, en lugar de dejar que la gente adivine.

[`L10N.md`](/docs/reference/l10n-md) los archivos proporcionan contexto de localización a nuestros agentes de traducción, al igual que `AGENTS.md` los archivos proporcionan instrucciones a los agentes de codificación. Ofrecen soporte para contexto más específico en directorios anidados, así como sobrescrituras de idioma en cada nivel.

Para información que se aplica a más de un repositorio, como terminología compartida, el servidor es la fuente de la verdad. El sistema se asegura de que se usa el contexto correcto y lo refleja en el archivo de bloqueo. Cuando ese contexto cambia, podemos mapear el cambio de vuelta a las traducciones que lo usaron y que necesitan ser actualizadas.

## Construyendo confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para lograrlo, contamos con varias herramientas.

La primera son verificaciones adversarias que se ejecutan después de la traducción. Piensa en un compañero revisando el código que has incluido en una solicitud de extracción. Aquí, las verificaciones traen conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debería agregar o quitar significado de la fuente. Esto puede ocurrir porque los modelos de lenguaje no siempre producen la misma salida a partir de las mismas entradas.

A medida que aprendemos más de nuestros usuarios y de nuestra propia investigación sobre modelos y sistemas existentes, añadiremos más verificaciones automatizadas al flujo de trabajo. Cada una debería aumentar la confianza que puedes tener en una traducción.

La idea es llegar a un punto donde confíes en el sistema lo suficiente como para no sentir la necesidad de revisar cada solicitud de extracción. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudar a elegir modelos basados en el idioma objetivo, ya que no todos los modelos son igualmente buenos con los mismos idiomas.

A pesar de esas comprobaciones, es posible que necesites cambiar un fragmento traducido. Podría ser una corrección puntual, terminología que aún no ha sido integrada al contexto, o uno de los muchos escenarios con los que aún nos toparemos.

Alguien debería poder aportar esos cambios directamente al repositorio. Pero también creemos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo reconciliarlas con su contexto. Eso podría significar agregar un término al glosario o ajustar la voz.

Esto es algo que una persona puede hacer de forma asíncrona, sin interrumpir la traducción continua. El sistema debería ayudarte a que sea más eficaz en su trabajo, aprendiendo de lo que la gente tiene que decir. Podríamos extender eso a permitir que las personas sugieran retroalimentación directamente desde el producto. ¿No sería eso genial?

Esas correcciones también deben tenerse en cuenta para que las futuras traducciones no las sobrescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios que las personas realizaron antes que ella. En los sistemas tradicionales, las memorias de traducción ayudan a cubrir ese papel. La necesidad que sirven no desaparece solo porque la tecnología cambie.

## A dónde vamos desde aquí

Esto es Glossia. Ya lo usamos para traducir Glossia, y estoy trabajando en configurarlo para traducir la documentación de Tuist, el sitio de marketing y el tablero a los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha sido parte de nuestras conversaciones durante años.

En la programación, muchas personas cuestionan el papel de los programadores y cómo evolucionará. Creo que la industria de la localización se beneficiaría de un cuestionamiento similar de sus supuestos y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y a menor costo, sin comprometer la calidad?

Aún no tenemos respuestas a todas las preguntas. Pero creemos que vamos en la dirección correcta, con la simplicidad y la atención al detalle que dedicamos a todo lo que hacemos.

Si esto resuena con usted, [hablemos](mailto:pedro@glossia.ai).