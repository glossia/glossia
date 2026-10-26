%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre idiomas, entrega de software y confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---

Los idiomas son una gran y poco reconocida herramienta para la accesibilidad y para llevar productos tecnológicos a nuevos mercados. Cuando su producto habla con comunidades cuyo idioma principal no es el inglés, usted señala que pensó en ellas. Eso puede establecer una conexión muy profunda.

Por desgracia, hacer que su producto y marca hablen varios idiomas es algo que muchos equipos no pueden costear. A menudo se ven obligados a elegir dos de tres: **calidad, velocidad y costes**.

Si quieren que las traducciones mantengan el ritmo de la entrega de software, pueden invertir en un equipo dedicado de personas para mantener la calidad, pero eso tiene un costo. O pueden confiar más en la traducción automática, moviéndose rápido pero aceptando una calidad menor. Si eligen calidad y bajo costo, confiando en la traducción humana sin un equipo dedicado, usualmente sacrifican la velocidad. A lo largo del camino, acaban con sistemas tortuosos que empujan y tiran de las traducciones entre sus repositorios y herramientas de terceros.

Desde la aparición de [grandes modelos de lenguaje](https://en.wikipedia.org/wiki/Large_language_model), mi esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), y yo hemos hablado mucho sobre si podrían ayudarnos a dejar de hacer esos compromisos. Ella ama los idiomas y está profundamente arraigada en la industria de la localización. Yo soy un constructor.

Tuist es mi principal trabajo. Cuando intenté traducir el producto y sus superficies de marketing, me encontré lidiando con soluciones complicadas. Ninguna de ellas se mantuvo al ritmo de nuestra velocidad de entrega, y algunas llevaron a conflictos que fueron una pesadilla para resolver. Tuve ese momento de "esto se siente incorrecto" muchas veces.

## De las conversaciones a Glossia

Cada semana, discutíamos nuevos patrones emergentes alrededor de las capacidades de los modelos de lenguaje. Vimos a cada vez más desarrolladores construyendo sus propias tuberías de traducción. En su núcleo, estas tuberías se basaban en un modelo: idioma fuente entrante, traducción saliente, y luego continuar.

Se sentía comprensible. Así es como operamos nosotros, los constructores. Pero alguien más cercano a los idiomas y los procesos alrededor de ellos podría ver cómo podría dar fallas, desde inconsistencias en el mejor de los casos hasta maltraducciones en el peor.

Los desarrolladores están moviéndose más rápido y más rápido. No pueden ralentizarse para introducir un sistema cuyos flujos de trabajo subyacentes fueron diseñados mucho antes de internet, movidos a un navegador, y que todavía luchan por satisfacer las necesidades de los equipos de software.

Así es como comenzó la idea de construir Glossia. Por un lado, apostaríamos por modelos que mejoren en idiomas aparte del inglés y en la traducción. Por otro, construiríamos un sistema, inicialmente enfocado en el contenido de software, que se sintiera listo para usar. Algo que correría en segundo plano, coincidiendo con su velocidad de entrega y dándole confianza de que la salida es correcta y lista para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo prompt. Algunos tokens, inglés entrada, traducción salida, y llamarlo terminado. Pero cuando hablas con ellos, te das cuenta de que no saben si la salida es precisa, captura la voz de su organización en ese idioma, o comunica el mensaje previsto efectivamente.

Tengo una tubería similar en Tuist, traduciendo a idiomas como el japonés, y lo hago con una enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar que el formato sea correcto, pero eso no nos dice **si las palabras son correctas**.

"La traducción es la parte fácil," como mi esposa gusta decir.

Así que embarcamos en averiguar cómo podría parecer el sistema correcto. Lo llamamos Glossia, y estamos empezando a abrirlo a personas y organizaciones interesadas en ayudarnos a iterarlo juntas.

## Decidir qué traducir

La primera pieza en la que nos enfocamos fue ayudar a las personas a decidir qué traducir. El costo de la traducción está bajando y continuará bajando, pero nunca será cero. Las organizaciones aún deberían ser selectivas sobre los idiomas en los que invierten.

A veces esa elección sigue directamente de una decisión empresarial. Otras veces, los equipos tienen una idea vaga de sus comunidades y hacen una estimación informada. Pensamos que había mucho que aprender de las personas que visitaban sus sitios web o usaban sus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones desde las que usan sus productos, pueden darte una base mejor para esas decisiones.

La primera característica en la que aterrizamos en Glossia fue el análisis. Añade una línea de código a tu sitio web, y el análisis comienza fluyendo a tu cuenta. Presentamos esa información alrededor de la decisión que necesitas tomar: ¿en qué idiomas debieras invertir a continuación?

Más adelante, exploraremos cómo llevar los experimentos a la dimensión de idioma de un producto. Imagina medir con qué frecuencia la gente hace clic en un llamado a la acción cuando una página usa diferentes voces en el mismo idioma. ¿No sería eso genial? Comparar variantes tradicionalmente ha gravitado alrededor de decisiones de producto y diseño, pero los idiomas son parte del producto también.

## Desde cero a traducción

Una vez que has decidido traducir un proyecto, el siguiente paso es configurarlo. Como desarrollador, odio procesos que traen mucha fricción. Acordamos que ir de cero a traducción idealmente debería tomar un solo paso. Ese es el nivel de experiencia por el que luchamos.

La configuración usualmente involucra dos cosas. Primero, extraer el contenido del repositorio para que pueda ser traducido, ya que usualmente empieza como cadenas literales en el código. Segundo, configurar el proyecto para elegir el contenido correcto basado en el idioma. Eso puede venir del dispositivo del usuario o, en casos más sofisticados, una preferencia que han elegido.

Automatizar esto reliablemente hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos con ello.

El proceso es así: conectas tu repositorio de GitHub, seleccionas los idiomas en los que quieres traducir, y, después de un tiempo, se abre un pull request con los cambios. Una vez que fusiones este, las traducciones comienzan a suceder. Eso es todo.

Mantemos las traducciones en el repositorio, junto con las comprobaciones de formato y otras validaciones que ya ejecutas como parte de [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). El pipeline de traducción alimenta los resultados de esas comprobaciones de vuelta al agente de traducción. Esto elimina toda una clase de problemas donde una plataforma abre una pull request y te deja lidiar con comprobaciones fallidas o conflictos de fusión.

Combinado con otros mecanismos para generar confianza, esto es lo que permite fusionar traducciones automáticamente. Ese es el modelo en el que creemos. Hay poco valor en pedirle a un desarrollador que verifique si una pull request de traducción está verde y haga clic en un botón, especialmente cuando no pueden evaluar el idioma ellos mismos. Siempre hemos visto esa ceremonia adicional como una señal de que el diseño podría ser mejor.

Creemos que el mejor sistema de traducción es aquel que funciona sin que tengas que pensar en él.

## Traduciendo solo lo que cambió

El sistema de traducción merece su propia sección. Los tokens aún no son gratuitos. Traducir todo el tiempo es lento, costoso y un desperdicio de recursos.

Para resolver eso, hemos creado un sistema de archivos de bloqueo que nos dice si algo necesita traducción. Llamamos a esto **traducción incremental**. La idea no es nueva: los sistemas de construcción la han usado durante mucho tiempo para evitar recompilar todo en cada compilación. Lo hemos adaptado a idiomas.

El sistema tiene en cuenta todo el contexto que afecta a una traducción específica. Parte de ese contexto vive en el repositorio. Parte vive en Glossia y abarca múltiples repositorios. Construimos un árbol de dependencia y usamos [árboles de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dicen si los inputs de una traducción han cambiado.

El archivo de bloqueo conserva ese árbol. Puede explicar por qué algo fue enviado para traducción, o por qué no lo fue, en lugar de dejar a la gente adivinando.

[`L10N.md`](/docs/reference/l10n-md) los archivos proporcionan contexto de localización a nuestros agentes de traducción, al igual que `AGENTS.md` los archivos proporcionan instrucciones a los agentes de codificación. Soportan un contexto más específico en directorios anidados, así como sobrescrituras de idioma en todos los niveles.

Para información que se aplica a más de un repositorio, como terminología compartida, el servidor es la fuente de verdad. El sistema se asegura de que utilice el contexto correcto y lo refleje en el archivo de bloqueo. Cuando ese contexto cambia, podemos rastrear el cambio de vuelta a las traducciones que lo usaron y necesitan actualizarse.

## Generando confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para llegar ahí, tenemos varias herramientas.

La primera son las comprobaciones adversarias que se ejecutan después de la traducción. Imagina a un compañero revisando el código que incluyes en una pull request. Aquí, las comprobaciones llevan conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debe agregar o eliminar significado de la fuente. Esto puede pasar porque los modelos de lenguaje no siempre producen la misma salida con las mismas entradas.

A medida que aprendemos más de nuestros usuarios y de nuestra propia investigación sobre modelos y sistemas existentes, añadiremos más comprobaciones automatizadas a la pipeline. Cada una debería aumentar la confianza que puedes tener en una traducción.

La idea es llegar a un punto donde confías en el sistema lo suficiente para no sentir la necesidad de revisar cada pull request. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudarte a elegir modelos basados en el idioma objetivo, porque no todos los modelos son igualmente buenos en los mismos idiomas.

Aunque tengan esas comprobaciones, es posible que necesites cambiar un tramo de traducción. Podría ser una corrección única, terminología que aún no se ha escrito en el contexto, o uno de los muchos escenarios que todavía tenemos que encontrar.

Alguien debería poder contribuir esos cambios directamente al repositorio. Pero también creemos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo alcanzar un acuerdo con su contexto. Eso podría significar agregar un término al glosario o ajustar la voz.

Esto es algo que una persona puede hacer de forma asincrónica, sin interrumpir la traducción continua. El sistema debería ayudarte a hacerlo más efectivo en su trabajo aprendiendo de lo que la gente tiene que decir. Podríamos extender eso a la gente que sugiera retroalimentación directamente desde el producto. ¿No sería eso genial?

Esas correcciones también deben tenerse en cuenta para que las traducciones futuras no las reescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios que hizo la gente antes. En sistemas tradicionales, las memorias de traducción ayudan a cumplir ese rol. La necesidad que sirven no desaparece solo porque cambia la tecnología.

## A dónde vamos desde aquí

Esto es Glossia. Ya lo usamos para traducir a Glossia, y estoy trabajando en configurarlo para traducir la documentación de Tuist, su sitio web de marketing y su tablero en los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha sido parte de nuestras conversaciones durante años.

En programación, muchas personas cuestionan el rol de los programadores y cómo evolucionará. Creo que la industria de localización beneficiaría de un cuestionamiento similar de sus supuestos y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y a un menor costo, sin comprometer la calidad?

Aún no tenemos respuestas a todas las preguntas. Pero creemos que nos dirigimos en la dirección correcta, con la simplicidad y la atención al oficio que nos gusta poner en todo lo que hacemos.

[hablemos](mailto:pedro@glossia.ai)
