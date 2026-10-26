%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre idiomas, la entrega de software y la confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---

Los idiomas son una gran y poco valorada herramienta para la accesibilidad y para llevar productos tecnológicos a nuevos mercados. Cuando tu producto habla con comunidades cuyo idioma principal no es inglés, señales que pienso en ellas. Eso puede establecer una conexión muy profunda.

Desafortunadamente, hacer que tu producto y marca hablen en varios idiomas es algo que muchas equipos no pueden permitirse. Suelen encontrarse teniendo que elegir dos de tres: **calidad, velocidad y costo**.

Si desean que las traducciones mantengan el ritmo con la entrega de software, pueden invertir en un equipo dedicado de personas para mantener la calidad, pero eso tiene un precio. O pueden apoyarse más en la traducción automática, moviéndose rápido pero aceptando una calidad inferior. Si eligen calidad y bajo costo, confiando en la traducción humana sin un equipo dedicado, usualmente sacrifican la velocidad. A lo largo del camino, terminan con sistemas convolucionados impulsando y extrayendo traducciones entre sus repositorios y herramientas de terceros.

Desde que surgieron [grandes modelos de lenguaje](https://en.wikipedia.org/wiki/Large_language_model), mi esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), y yo hemos hablado mucho sobre si podrían ayudarnos a dejar de hacer esos compromisos. Ella ama los idiomas y está profundamente involucrada en la industria de la localización. Yo soy un constructor.

Tuist es mi trabajo principal. Cuando traté de traducir el producto y sus superficies de marketing, me vi lidiando con soluciones convolucionadas. Ninguna de ellas mantuvo el ritmo con nuestra velocidad de entrega, y algunas llevaron a conflictos que eran una pesadilla para resolver. Tuve ese momento de "esto se siente mal" muchas veces.

## De las conversaciones a Glossia

Cada semana, discutíamos nuevos patrones emergentes alrededor de las capacidades de los modelos de lenguaje. Vimos a cada vez más desarrolladores construyendo sus propias cadenas de traducción. En su núcleo, estas cadenas daban pauta a un modelo: idioma de entrada, traducción de salida, y luego continuar.

Parecía comprensible. Es así como operamos los constructores. Pero alguien más cerca de los idiomas y los procesos alrededor de ellos podría ver cómo podría ir mal, de las inconsistencias en el mejor de los casos a las traducciones erróneas en el peor de los casos.

Los desarrolladores se mueven más y más rápido. No pueden frenarse para introducir un sistema cuyos flujos de trabajo subyacentes fueron diseñados mucho antes de internet, movidos a un navegador y que aún luchan por satisfacer las necesidades de los equipos de software.

Así es como comenzó la idea de construir Glossia. Por un lado, apostaríamos a que los modelos mejoraran en idiomas además del inglés y en la traducción. Por otro, construiríamos un sistema, inicialmente enfocado en contenido de software, que se sintiera como plug-and-play. Algo que corre en segundo plano, que coincide con tu velocidad de entrega, y que te da confianza de que la salida es correcta y lista para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo prompt. Algunos tokens, inglés de entrada, traducción de salida, y la llaman terminada. Pero cuando hablas con ellos, te das cuenta de que no saben si la salida es precisa, captura la voz de su organización en ese idioma, o comunica el mensaje intencionado de manera efectiva.

Tengo una cadena similar en Tuist, traduciendo en idiomas como el japonés, y lo hago con una enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar que el formato sea correcto, pero eso no nos dice **si las palabras son correctas**.

"La traducción es la parte fácil," como le gusta decir a mi esposa.

Así que nos embarcamos en descubrir cómo se vería un sistema correcto. Lo llamamos Glossia, y estamos empezando a abrirlo a personas y organizaciones interesadas en ayudarnos a iterar sobre él juntos.

## Decidir qué traducir

La primera pieza en la que nos enfocamos fue ayudar a la gente a decidir qué traducir. El costo de la traducción está bajando y continuará bajando, pero nunca será cero. Las organizaciones aún deberían ser selectivas sobre los idiomas en los que invierten.

A veces, esa elección sigue directamente de una decisión de negocio. Otras veces, los equipos tienen una idea general de sus comunidades y hacen una suposición fundamentada. Creíamos que había mucho por aprender de las personas que visitan tus sitios web o usan tus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones desde las cuales usan tus productos, pueden darte una mejor base para esas decisiones.

La primera función que implementamos en Glossia fue análisis. Añade una línea de código a tu sitio web, y el análisis comienza a fluir hacia tu cuenta. Presentamos esa información alrededor de la decisión que necesitas tomar: ¿en qué idiomas debería invertir a continuación?

Con el tiempo, exploraremos cómo llevar los experimentos a la dimensión del idioma de un producto. Imagina medir con qué frecuencia las personas hacen clic en una llamada a la acción cuando una página usa diferentes voces en el mismo idioma. ¿No sería genial? Comparar variantes tradicionalmente ha gravitado alrededor de decisiones de producto y diseño, pero los idiomas son parte del producto también.

## Del cero a la traducción

Una vez que has decidido traducir un proyecto, el siguiente paso es configurarlo. Como desarrollador, desaprovo procesos que vienen con mucha fricción. Llegamos a acordar que ir del cero a la traducción debería idealmente tomar un paso. Ese es el nivel de experiencia por el que luchamos.

La configuración generalmente implica dos cosas. Primero, extraer el contenido del repositorio para que pueda ser traducido, ya que a menudo comienza como cadenas de texto literales en el código. Segundo, configurar el proyecto para elegir el contenido correcto según el idioma. Eso podría provenir del dispositivo del usuario o, en casos más sofisticados, una preferencia que han elegido.

Automatizar esto confiablemente hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos en eso.

El proceso funciona así: conectas tu repositorio de GitHub, seleccionas los idiomas en los que quieres traducir, y, después de un tiempo, una solicitud de extracción se abre con los cambios. Una vez que la fusionas, las traducciones comienzan a ocurrir. Eso es todo.

Mantemos las traducciones en el repositorio, junto con los controles de formato y otras validaciones que ya ejecutas como parte de [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). La tubería de traducción alimenta los resultados de esos controles de nuevo al agente de traducción. Esto elimina una clase entera de problemas donde una plataforma abre una solicitud de extracción y te deja tener que tratar con controles fallidos o conflictos de fusión.

Combinado con otros mecanismos para generar confianza, esto es lo que permite fusionar las traducciones automáticamente. Ese es el modelo en el que creemos. Hay poco valor en pedirle a un desarrollador que verifique si una solicitud de extracción de traducción está verde y haga clic en un botón, especialmente cuando no pueden evaluar el idioma por sí mismos. Siempre hemos visto esa ceremonia adicional como una señal de que el diseño podría mejorar.

Creemos que el mejor sistema de traducción es aquel que funciona sin que tengas que pensar en él.

## Traducir únicamente lo que cambió

El sistema de traducción merece su propia sección. Los tokens todavía no son gratuitos. Traducir todo todo el tiempo es lento, costoso y un desperdicio de recursos.

Para resolver eso, hemos construido un sistema de archivo de bloqueo que nos indica si algo necesita ser traducido. Llamamos a esto **traducción incremental**. La idea no es nueva: los sistemas de compilación la han usado durante mucho tiempo para evitar volver a compilar todo en cada compilación. La hemos adaptado a los idiomas.

El sistema tiene en cuenta todo el contexto que afecta a una traducción en particular. Parte de ese contexto reside en el repositorio. Otra parte reside en Glossia y abarca múltiples repositorios. Construimos un árbol de dependencias y usamos [árboles de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos indican si las entradas de una traducción han cambiado.

El archivo de bloqueo preserva ese árbol. Puede explicar por qué algo se envió para traducir, o por qué no, en lugar de dejar que la gente especule.

Los archivos [`L10N.md`](/docs/reference/l10n-md) proporcionan contexto de localización a nuestros agentes de traducción, de manera similar a los archivos `AGENTS.md` que proporcionan instrucciones a los agentes de código. Admiten un contexto más específico en directorios anidados, así como sobrescrituras de idioma en cada nivel.

Para la información que se aplica a más de un repositorio, como la terminología compartida, el servidor es la fuente de verdad. El sistema se asegura de que use el contexto correcto y lo refleje en el archivo de bloqueo. Cuando ese contexto cambia, podemos rastrear el cambio de vuelta a las traducciones que lo usaron y necesitan actualización.

## Generar confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para lograrlo, contamos con varias herramientas.

La primera son comprobaciones adversariales que se ejecutan después de la traducción. Imagina un compañero revisando el código que has incluido en una solicitud de extracción. Aquí, las comprobaciones traen conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debería añadir o quitar significado de la fuente. Eso puede pasar porque los modelos de lenguaje no siempre producen el mismo resultado de las mismas entradas.

A medida que aprendemos más de nuestros usuarios y de nuestra propia investigación sobre modelos y sistemas existentes, añadiremos más comprobaciones automatizadas a la tubería. Cada una debería aumentar la confianza que puedas tener en una traducción.

La idea es llegar a un punto donde confías en el sistema lo suficiente para que no sientas la necesidad de revisar cada solicitud de extracción. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudar a seleccionar modelos según el idioma objetivo, porque no todos los modelos son igualmente buenos en los mismos idiomas.

Aunque estén en su lugar esas comprobaciones, podrías necesitar cambiar una pieza traducida. Podría ser una corrección puntual, terminología que aún no se ha introducido en el contexto, o uno de los muchos escenarios que aún tenemos por delante.

Alguien debería poder contribuir esos cambios directamente al repositorio. Pero también pensamos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo reconciliarlas con su contexto. Eso podría significar añadir un término al glosario o ajustar la voz.

Esto es algo que una persona puede hacer de forma asíncrona, sin interrumpir la traducción continua. El sistema debería ayudarte a que sea más efectivo en su trabajo aprendiendo de lo que la gente dice. Podríamos extender eso a que la gente sugiera retroalimentación directamente desde el producto. ¿No sería genial?

Esas correcciones también deben tenerse en cuenta para que las traducciones futuras no las sobrescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios realizados por la gente antes. En sistemas tradicionales, las memorias de traducción ayudan a cubrir ese rol. La necesidad que sirven no desaparece solo porque la tecnología cambia.

## Hacia dónde vamos desde aquí

Esto es Glossia. Ya lo usamos para traducir a Glossia, y estoy trabajando en configurarlo para traducir la documentación de Tuist, el sitio de marketing y el panel de control a los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha estado presente en nuestras conversaciones durante años.

En programación, muchas personas están cuestionando el rol de los programadores y cómo evolucionará. Creo que la industria de la localización se beneficiaría de un cuestionamiento similar de sus suposiciones y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y a un menor costo, sin comprometer la calidad?

Aún no tenemos respuestas a todas las preguntas. Pero creemos que vamos en la dirección correcta, con la simplicidad y atención al detalle que solemos verter en todo lo que hacemos.

Si esto resuena contigo, [hablemos](mailto:pedro@glossia.ai).
