%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre idiomas, entrega de software y confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---

Los idiomas son una gran herramienta a menudo infravalorada para la accesibilidad y para introducir productos tecnológicos en nuevos mercados. Cuando tu producto se dirige a comunidades cuya lengua principal no es el inglés, señalas que las has tenido en cuenta. Eso puede establecer una conexión muy profunda.

Lamentablemente, hacer que tu producto y tu marca hablen varios idiomas es algo de lo que muchos equipos no se pueden permitir. A menudo se enfrentan a elegir dos de tres: **calidad, velocidad y coste**.

Si desean que las traducciones mantengan el ritmo con la entrega de software, pueden invertir en un equipo dedicado de personas para mantener la calidad, pero eso conlleva un coste. O pueden apoyarse más en la traducción automática, avanzando rápido pero aceptando una calidad inferior. Si optan por calidad y bajo costes, basándose en la traducción humana sin un equipo dedicado, normalmente sacrifican la velocidad. A lo largo del camino, terminan con sistemas convolutos que mueven traducciones de ida y vuelta entre sus repositorios y herramientas de terceros.

Desde que [los modelos de lenguaje grandes](https://en.wikipedia.org/wiki/Large_language_model) surgieron, mi esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), y yo hemos hablado mucho de si podrían ayudarnos a dejar de hacer esos compromisos. A ella le encantan los idiomas y está profundamente involucrada en la industria de la localización. Yo soy un constructor.

Tuist es mi trabajo principal. Cuando intenté traducir el producto y sus superficies de marketing, me encontré manejando soluciones convolutas. Ninguna de ellas se mantuvo al día con nuestra velocidad de entrega, y algunas derivaron en conflictos que eran una pesadilla para resolver. Tuve ese momento de “esto se siente mal” muchas veces.

## ## De las conversaciones a Glossia

Cada semana, debatíamos sobre nuevos patrones emergentes alrededor de las capacidades de los modelos de lenguaje. Vimos a más y más desarrolladores construir sus propios pipelines de traducción. En el núcleo, estos pipelines requerían un modelo: idioma de origen entra, traducción sale, y luego continuar.

Se sentía comprensible. Así es como operamos los desarrolladores. Pero alguien más cercano a los idiomas y a los procesos alrededor de ellos podía ver cómo podía ir mal, desde inconsistencias como máximo a traducciones erróneas como mínimo.

Los desarrolladores se mueven cada vez más rápido. No pueden ralentizarse para introducir un sistema cuyos flujos de trabajo subyacentes fueron diseñados mucho antes de internet, se movieron a un navegador y aún luchan por satisfacer las necesidades de los equipos de software.

Así es como empezó la idea de construir Glossia. Por un lado, apostamos por que los modelos mejorarían en idiomas otres que el inglés y en la traducción. Por otro, construiríamos un sistema, inicialmente enfocado en el contenido de software, que se sintiera plug and play. Algo que corre en segundo plano, que coincida con la velocidad de tu entrega, y que inspire confianza de que la salida es correcta y lista para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo prompt. Algunos tokens, inglés entra, traducción sale, y lo consideramos terminado. Pero cuando hablas con ellos, te das cuenta de que no saben si la salida es precisa, captura la voz de su organización en ese idioma, o comunica el mensaje intencional eficazmente.

Tengo un pipeline similar en Tuist, traduciendo a idiomas como el japonés, y lo hago con una enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar que el formato es correcto, pero eso no nos dice **si las palabras son correctas**.

“La traducción es la parte fácil”, como le gusta decir a mi esposa.

Así que emprendimos averiguar cómo podría parecer el sistema adecuado. Lo llamamos Glossia, y empezamos a abrirlo a personas y organizaciones interesadas en ayudarnos a iterar sobre él conjuntamente.

## Decidir qué traducir

La primera pieza en la que nos enfocamos fue ayudar a las personas a decidir qué traducir. El coste de la traducción está bajando y continuará bajando, pero nunca será cero. Las organizaciones aún deben ser selectivas sobre los idiomas en los que invierten.

A veces esa opción sigue directamente de una decisión de negocio. Otras veces, los equipos tienen una idea general de sus comunidades y hacen una suposición informada. Pensamos que había mucho que aprender de la gente que visita tus sitios web o usa tus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones desde las que utilizan tus productos, pueden darte una base mejor para esas decisiones.

El primer elemento que incorporamos en Glossia fue la analítica. Añade una línea de código a tu sitio web, y la analítica empieza a fluir hacia tu cuenta. Presentamos esa información alrededor de la decisión que necesitas tomar: ¿en qué idiomas deberías invertir a continuación?

A futuro, exploraremos cómo introducir experimentos en la dimensión del idioma de un producto. Imagina medir qué tan a menudo la gente hace clic en una llamada a la acción cuando una página usa diferentes voces en el mismo idioma. ¿No sería genial? Comparar variantes ha gravitado tradicionalmente alrededor de decisiones de producto y diseño, pero los idiomas son parte del producto también.

## De cero a traducción

Una vez que has decidido traducir un proyecto, el siguiente paso es configurarlo. Como desarrollador, me disgustan los procesos que vienen con mucha fricción. Acordamos que ir de cero a traducción debería idealmente tomar un paso. Ese es el nivel de experiencia por el que luchamos.

La configuración usualmente implica dos cosas. Primero, extraer el contenido del repositorio para que se pueda traducir, ya que a menudo comienza como cadenas literales en el código. Segundo, configurar el proyecto para seleccionar el contenido adecuado según el idioma. Eso puede venir del dispositivo del usuario o, en casos más sofisticados, una preferencia que han elegido.

Automatizar esto de manera confiable hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos con esto.

El proceso funciona así: conectas tu repositorio de GitHub, seleccionas los idiomas en los que quieres traducir, y, tras un tiempo, se abre una solicitud de extracción con los cambios. Una vez la fusiones, las traducciones comienzan a suceder. Eso es todo.

Mantendemos las traducciones en el repositorio, junto a los controles de formato y otras validaciones que ya ejecutas como parte de la [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). La tubería de traducción retroalimenta los resultados de esos controles al agente de traducción. Eso elimina toda una clase de problemas en los que una plataforma abre una solicitud de extracción y te deja lidiar con controles fallidos o conflictos de fusión.

En combinación con otros mecanismos para generar confianza, esta es lo que hace posible fusionar traducciones automáticamente. Ese es el modelo en el que creemos. Hay poco valor en pedirle a un desarrollador que verifique si una solicitud de extracción de traducción está verde y haga clic en un botón, especialmente cuando ellos tampoco pueden evaluar el idioma por sí mismos. Siempre hemos visto esa ceremonia adicional como una señal de que el diseño podría ser mejor.

Creemos que el mejor sistema de traducción es el que funciona sin que tengas que pensar en ello.

## Traducir solo lo que cambió

El sistema de traducción merece su propia sección. Los tokens aún no son gratuitos. Traducir todo siempre es lento, costoso y un desperdicio de recursos.

Para solucionar eso, hemos construido un sistema de archivo de bloqueo que nos dice si algo necesita traducirse. Lo llamamos **traducción incremental**. La idea no es nueva: los sistemas de compilación la han usado por mucho tiempo para evitar recompilarlo todo en cada compilación. Lo hemos adaptado a idiomas.

El sistema tiene en cuenta todo el contexto que afecta una traducción en particular. Parte de ese contexto vive en el repositorio. Algunas partes viven en Glossia y abarcan múltiples repositorios. Construimos un árbol de dependencias y usamos [árboles de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dicen si las entradas de una traducción han cambiado.

El archivo de bloqueo preserva ese árbol. Puede explicar por qué algo se envió para traducir, o por qué no, en lugar de dejar a la gente adivinando.

[`L10N.md`](/docs/reference/l10n-md) archivos proporcionan contexto de localización a nuestros agentes de traducción, al igual que `AGENTS.md` archivos proporcionan instrucciones a los agentes de codificación. Estos soportan un contexto más específico en directorios anidados, así como sobrescrituras de idioma en cada nivel.

Para información que se aplica a más de un repositorio, como terminología compartida, el servidor es la fuente de la verdad. El sistema se asegura de que use el contexto adecuado y lo refleje en el archivo de bloqueo. Cuando ese contexto cambia, podemos mapear el cambio de vuelta a las traducciones que lo usaron y necesitan actualizarse.

## Generar confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para lograrlo, tenemos varias herramientas.

La primera son controles adversarios que se ejecutan después de la traducción. Piensa en un colega revisando el código que has incluido en una solicitud de extracción. Aquí, los controles traen conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debe agregar o eliminar significado de la fuente. Eso puede pasar porque los modelos de lenguaje no siempre producen el mismo output de las mismas entradas.

A medida que aprendemos más de nuestros usuarios y de nuestra propia investigación en modelos y sistemas existentes, agregaremos más controles automatizados a la tubería. Cada uno debe aumentar la confianza que puedas tener en una traducción.

La idea es llegar a un punto donde confíes en el sistema lo suficiente para que no sientas necesidad de revisar cada solicitud de extracción. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudar a seleccionar modelos basados en el idioma objetivo, porque no todos los modelos son igualmente buenos en los mismos idiomas.

Incluso con esos controles en lugar, quizás necesites cambiar una pieza traducida. Puede ser una corrección de único caso, terminología que aún no ha sido escrita en el contexto, o uno de los muchos escenarios que aún tenemos que encontrar.

Alguien debería poder contribuir esos cambios directamente al repositorio. Pero también pensamos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo reconciliarlas con su contexto. Eso podría significar agregar un término al glosario o ajustar el tono de voz.

Eso es algo que una persona puede hacer de manera asíncrona, sin interrumpir la traducción continua. El sistema debería ayudarte a hacerlo más efectivo en su trabajo aprendiendo de lo que dice la gente. Podríamos extender eso a que la gente sugiera retroalimentación directamente desde el producto. ¿No sería genial?

Esas correcciones también deben tenerse en cuenta para que las traducciones futuras no las sobrescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios que la gente hizo antes de ella. En sistemas tradicionales, los memorias de traducción ayudan a llenar ese papel. La necesidad que sirven no desaparece solo porque cambia la tecnología.

## Donde vamos desde aquí

Esta es Glossia. Ya la usamos para traducir Glossia, y estoy trabajando en configurarla para traducir la documentación de Tuist, el sitio web de marketing y el panel de control a los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha sido parte de nuestras conversaciones durante años.

En programación, mucha gente está cuestionando el rol de los programadores y cómo evoluciona. Creo que la industria de localización se beneficiaría de un cuestionamiento similar de sus suposiciones y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y a menor costo, sin comprometer la calidad?

Aún no tenemos respuestas para todas las preguntas. Pero creemos que nos dirigimos en la dirección correcta, con la simplicidad y atención al oficio que nos gusta vertir en todo lo que hacemos.

Si esto resuena contigo, [pongámonos en contacto](mailto:pedro@glossia.ai).
