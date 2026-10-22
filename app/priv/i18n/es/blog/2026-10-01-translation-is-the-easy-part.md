%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre lenguajes, la entrega de software y la confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---

Los idiomas son una gran y poco valorada herramienta para la accesibilidad y llevar productos tecnológicos a nuevos mercados. Cuando tu producto habla con comunidades cuyo idioma principal no es el inglés, señalas que les habías pensado. Eso puede establecer una conexión muy profunda.

Desafortunadamente, hacer que tu producto y marca hablen varios idiomas es algo que muchos equipos no pueden permitirse. A menudo se encuentran a sí mismos teniendo que elegir dos de tres: **calidad, velocidad y costo**.

Si desean que las traducciones mantengan el ritmo con la entrega de software, pueden invertir en un equipo dedicado para mantener la calidad, pero eso conlleva un costo. O pueden apoyarse más firmemente en la traducción automática, moviéndose rápido pero aceptando menor calidad. Si eligen calidad y bajo costo, confiando en la traducción humana sin un equipo dedicado, usualmente sacrifican la velocidad. En el camino, terminan con sistemas convolutos empujando y sacando traducciones entre sus repositorios y herramientas de terceros.

Desde que surgieron [modelos de lenguaje a gran escala](https://en.wikipedia.org/wiki/Large_language_model), mi esposa [María José](https://www.linkedin.com/in/mariajosesalmeron/) y yo hemos hablado mucho sobre si pourraient ayudarnos a dejar de hacer esos compromisos. Ella ama los idiomas y está profundamente inmersa en la industria de la localización. Yo soy un constructor.

Tuist es mi trabajo principal. Cuando intenté traducir el producto y sus superficies de marketing, me encontré lidiando con soluciones enredadas. Ninguna mantuvo el ritmo con nuestra velocidad de entrega, y algunas llevaron a conflictos que eran una pesadilla de resolver. He tenido ese momento de "esto se siente mal" muchas veces.

## De conversaciones a Glossia

Cada semana, discutíamos los nuevos patrones emergentes en torno a las capacidades de los modelos de lenguaje. Vimos a más y más desarrolladores construyendo sus propias tuberías de traducción. En esencia, estas tuberías implicaban un modelo: entrada de idioma fuente, traducción de salida, y luego continuar.

Se sentía comprensible. Así es como operamos los constructores. Pero alguien más cercano a los idiomas y los procesos que los rodean podía ver cómo podría ir mal, desde inconsistencias en el mejor de los casos hasta malas traducciones en el peor de los casos.

Los desarrolladores avanzan cada vez más rápido. No pueden ralentizar para introducir un sistema cuyos flujos de trabajo subyacentes fueron diseñados mucho antes de internet, pasó a un navegador y aún lucha para satisfacer las necesidades de los equipos de software.

Así es como comenzó la idea de construir Glossia. Por un lado, apostamos por que los modelos mejoren en idiomas que no son inglés y en traducción. Por otro lado, construiríamos un sistema, inicialmente enfocado en contenido de software, que se sintiera plug and play. Algo que funcionara en segundo plano, coincidiendo con tu velocidad de entrega y dándote confianza de que la salida es correcta y lista para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo prompt. Algunos tokens, inglés dentro, traducción fuera, y listo. Pero cuando hablas con ellos, te das cuenta de que no saben si la salida es precisa, capta la voz de su organización en ese idioma, o comunica el mensaje intencionado eficazmente.

Tengo una tubería similar en Tuist, traduciendo a idiomas como el japonés, y lo hago con una enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar que el formato sea correcto, pero eso no nos dice **si las palabras son las correctas**.

"La traducción es la parte fácil", como dice mi esposa.

Así nos embarcamos en averiguar qué aspecto tendría el sistema correcto. Lo llamamos Glossia, y estamos empezando a abrirlo a personas y organizaciones interesadas en ayudarnos a iterarlo juntas.

## Decidir qué traducir

La primera funcionalidad en la que nos enfocamos fue ayudar a la gente a decidir qué traducir. El costo de la traducción está bajando y seguirá bajando, pero nunca será cero. Las organizaciones aún deberían ser selectivas sobre los idiomas en los que invierten.

A veces esa elección sigue directamente de una decisión comercial. Otras veces, los equipos tienen una idea aproximada de sus comunidades y hacen una estimación informada. Pensamos que había mucho que aprender de las personas que visitan tus sitios web o usan tus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones desde las cuales usan tus productos, pueden darte una base mejor para esas decisiones.

La primera funcionalidad que implementamos en Glossia fue el análisis. Añade una línea de código a tu sitio web, y el análisis comienza a llegar a tu cuenta. Presentamos esa información en torno a la decisión que necesitas tomar: ¿en qué idiomas deberías invertir a continuación?

A futuro, exploraremos cómo llevar los experimentos a la dimensión de idioma de un producto. Imagina medir qué tan frecuentemente la gente hace clic en una llamada a la acción cuando una página usa diferentes voces en el mismo idioma. ¿No sería genial? Comparar variantes tradicionalmente ha gravitado en torno a decisiones de producto y diseño, pero los idiomas también son parte del producto.

## De cero a traducción

Una vez que decides traducir un proyecto, el siguiente paso es configurarlo. Como desarrollador, no me gustan los procesos que traen mucha fricción. Acordamos que pasar de cero a traducción idealmente debería tomar un paso. Ese es el nivel de experiencia en el que nos esforzamos.

La configuración usualmente implica dos cosas. Primero, extraer el contenido del repositorio para que pueda ser traducido, ya que a menudo comienza como cadenas literales en el código. Segundo, configurar el proyecto para seleccionar el contenido correcto según el idioma. Esto podría provenir del dispositivo del usuario o, en casos más sofisticados, una preferencia que han elegido.

Automatizar esto de manera confiable hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos para ello.

El proceso va así: conectas tu repositorio de GitHub, seleccionas los idiomas en los que quieres traducir, y, después de un tiempo, se abre un pull request con los cambios. Una vez que lo fusiones, las traducciones comienzan a suceder. Eso es todo.

Mantemos las traducciones en el repositorio, junto con las comprobaciones de formato y otras validaciones que ya ejecutas como parte de [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). El pipeline de traducción reintroduce los resultados de esas comprobaciones al agente de traducción. Esto elimina toda una clase de problemas donde una plataforma abre un pull request y te deja lidiar con comprobaciones fallidas o conflictos de fusión.

Combinado con otros mecanismos para construir confianza, esto es lo que puede hacer posible fusionar traducciones automáticamente. Ese es el modelo en el que creemos. No tiene mucho valor pedirle a un desarrollador que revise si un pull request de traducción tiene estado verde y hacer clic en un botón, especialmente cuando no pueden evaluar el idioma por sí mismos. Siempre hemos visto esa cerimonials extraña como un signo de que el diseño podría ser mejor.

Creemos que el mejor sistema de traducción es aquel que funciona sin que tengas que pensarlo.

## Traduciendo solo lo que cambió

El sistema de traducción merece su propia sección. Los tokens todavía no son gratuitos. Traducir todo todo el tiempo es lento, costoso y un desperdicio de recursos.

Para solucionar eso, hemos creado un sistema de archivo de bloqueo que nos indica si algo necesita traducción. Llamamos a esto **traducción incremental**. La idea no es nueva: los sistemas de compilación la han utilizado durante mucho tiempo para evitar recompilar todo en cada compilación. Ya la hemos adaptado a idiomas.

El sistema tiene en cuenta todo el contexto que afecta a una traducción en particular. Parte de ese contexto vive en el repositorio. Otra parte vive en Glossia y abarca múltiples repositorios. Creamos un árbol de dependencias y utilizamos [árboles de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos indican si las entradas de una traducción han cambiado.

El archivo de bloqueo preserva ese árbol. Puede explicar por qué algo fue enviado para traducción o por qué no, en lugar de dejar a la gente en la incertidumbre.

[`L10N.md`](/docs/reference/l10n-md) archivos proporcionan contexto de localización a nuestros agentes de traducción, muy similares a `AGENTS.md` archivos que proporcionan instrucciones a los agentes de codificación. Aportan contexto más específico en directorios anidados, así como superposiciones de idioma a todos los niveles.

Para la información que aplica a más de un repositorio, como la terminología compartida, el servidor es la fuente de la verdad. El sistema se asegura de usar el contexto correcto y reflejarlo en el archivo de bloqueo. Cuando ese contexto cambia, podemos mapear el cambio de vuelta a las traducciones que lo utilizaron y que necesitan ser actualizadas.

## Construyendo confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para llegar allí, tenemos varias herramientas.

La primera son las comprobaciones adversarias que se ejecutan después de la traducción. Piensa en un colega revisando el código que has incluido en un pull request. Aquí, las comprobaciones traen conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debería añadir o quitar significado del origen. Eso puede suceder porque los modelos de lenguaje no siempre producen el mismo resultado de los mismos inputs.

A medida que aprendamos más de nuestros usuarios y de nuestra propia investigación sobre modelos y sistemas existentes, añadiremos más comprobaciones automatizadas al pipeline. Cada una debería aumentar la confianza que puedes tener en una traducción.

La idea es llegar a un punto donde confíes en el sistema lo suficiente que no sientas la necesidad de pasar por cada pull request. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudar a elegir modelos basándonos en el idioma objetivo, porque no todos los modelos son igualmente buenos en los mismos idiomas.

Aunque estén en lugar esas comprobaciones, podría necesitar cambiar un fragmento traducido. Podría ser una corrección aislada, terminología que aún no se ha escrito en el contexto, o uno de los muchos escenarios por los que aún vamos a pasar.

Alguien debería poder contribuir esos cambios directamente al repositorio. Pero también creemos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo reconciliarlas con su contexto. Eso podría significar añadir un término al glosario o ajustar la voz.

Esto es algo que una persona puede hacer de manera asíncrona, sin interrumpir la traducción continua. El sistema debería ayudarte a hacerlo más efectivo en su trabajo aprendiendo de lo que la gente tiene que decir. Podríamos extender eso a la gente que sugiera retroalimentación directamente desde el producto. ¿No sería genial?

Esa corrección también necesita ser tomada en cuenta para que las futuras traducciones no las sobreescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios que la gente hizo antes de ella. En sistemas tradicionales, las memorias de traducción ayudan a cumplir ese rol. La necesidad que sirven no desaparece solo porque la tecnología cambia.

## A dónde vamos desde aquí

Esta es Glossia. Ya lo usamos para traducir Glossia, y estoy trabajando en configurarlo para traducir la documentación, el sitio web de marketing y el panel de control de Tuist a los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha sido parte de nuestras conversaciones durante años.

En programación, muchas personas están cuestionando el rol de los programadores y cómo evolucionará. Creo que la industria de la localización se beneficiaría de un cuestionamiento similar de sus supuestos y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y con menor costo, sin comprometer la calidad?

No tenemos todas las respuestas a las preguntas todavía. Pero creemos que nos dirigimos en la dirección correcta, con la simplicidad y la atención al oficio que nos gusta verter en todo lo que hacemos.

Si esto resuena contigo, [hablemos](mailto:pedro@glossia.ai).
