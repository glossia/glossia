%{
  title: "La traducción es la parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Cómo las conversaciones sobre idiomas, entrega de software y confianza llevaron a María José y a mí a construir Glossia.",
  author: "pedro"
}
---

Los idiomas son una gran y subestimada herramienta para la accesibilidad y llevar productos tecnológicos a nuevos mercados. Cuando su producto habla con comunidades de las cuales el idioma principal no es el inglés, usted se señala a sí mismo que les ha pensado en ello. Eso puede establecer una conexión muy profunda.

Desafortunadamente, hacer que su producto y su marca hablen varios idiomas es algo que muchos equipos no pueden permitirse. A menudo se ven obligados a elegir dos de tres: **calidad, velocidad y coste**.

Si desean que las traducciones mantengan ritmo con la entrega de software, pueden invertir en un equipo dedicado de personas para mantener la calidad, pero eso tiene un coste. O pueden basarse más entraducción automática, moviéndose rápido pero aceptando menor calidad. Si eligen calidad y bajo coste, confiando en la traducción humana sin un equipo dedicado, generalmente sacrifican velocidad. Asimismo, acaban con sistemas convolutos impulsando y arrastrando traducciones entre sus repositorios y herramientas de terceros.

Desde que surgieron [modelos de lenguaje a gran escala](https://en.wikipedia.org/wiki/Large_language_model), mi esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), y yo hemos hablado mucho sobre si podrían ayudarnos a dejar de hacer esos compromisos. Ella ama los idiomas y está profundamente integrada en la industria de la localización. Soy un constructor.

Tuist es mi trabajo principal. Cuando intenté traducir el producto y sus superficies de marketing, me encontré lidiando con soluciones convolutas. Ninguna de ellas se mantuvo al ritmo de nuestra velocidad de entrega, y algunas llevaron a conflictos que fueron una pesadilla para resolver. Tuve ese momento de «esto se siente mal» muchas veces.

## De conversaciones a Glossia

Cada semana, discutiríamos nuevos patrones emergentes alrededor de las capacidades de los modelos de lenguaje. Vimos a más y más desarrolladores construyendo sus propias tuberías de traducción. En su núcleo, estas tuberías impulsaban un modelo: idioma de entrada, traducción de salida, y luego seguir adelante.

Se sentía comprensible. Así es como operamos, los constructores. Pero alguien más cerca de los idiomas y los procesos alrededor de ellos podría ver cómo podría salir mal, desde inconsistencias como mucho como malas traducciones hasta el peor.

Los desarrolladores avanzan cada vez más rápido. No pueden frenar para introducir un sistema cuyo flujos de trabajo subyacentes se diseñaron mucho antes de internet, se movió a un navegador, y aún tiene dificultades para cumplir las necesidades de los equipos de software.

Así es como comenzó la idea de construir Glossia. En un lado, apostaríamos a que los modelos mejoren en idiomas diferentes al inglés y en traducción. Por otro, construiríamos un sistema, inicialmente enfocado en contenido de software, que se sintiera de plug and play. Algo ejecutándose en segundo plano, coincidiendo con su velocidad de entrega, y dándole confianza de que el output es correcto y listo para producción.

Muchos desarrolladores tratan la traducción como una solución de un solo comando. Algunos tokens, inglés de entrada, traducción de salida, y llamarlo hecho. Pero cuando hablan con ellos, te das cuenta de que no saben si el output es preciso, captura la voz de su organización en ese idioma, o comunica el mensaje intencionado efectivamente.

Tengo una tubería similar en Tuist, traduciendo a idiomas como japonés, y lo hago con un enorme falta de confianza. Los idiomas no son lógica. Podemos escribir pruebas para asegurar el formato es correcto, pero eso no nos dice **si las palabras son correctas**.

"La traducción es la parte fácil", como a mi esposa le gusta decir.

Así que embarcamos en descubrir qué podría parecer un sistema correcto. Lo llamamos Glossia, y estamos empezando a abrirlo a personas y organizaciones interesadas en ayudarnos a iterar sobre él juntos.

## Decidir qué traducir

La primera pieza en la que nos enfocamos fue ayudar a la gente a decidir qué traducir. El coste de la traducción está bajando y seguirá bajando, pero nunca será cero. Las organizaciones todavía deben ser selectivas sobre los idiomas en los que invierten.

A veces esa elección sigue directamente de una decisión de negocio. Otras veces, los equipos tienen una idea cruda de sus comunidades y hacen un educated guess. Pensamos que había mucho por aprender de las personas que visitan sus sitios web o usan sus aplicaciones. Sus preferencias de idioma, combinadas con información sobre las regiones para las cuales usan sus productos, les pueden dar una mejor base para esas decisiones.

La primera característica que aterrizamos en Glossia fue analíticas. Añada una línea de código a su sitio web, y las analíticas empiezan a fluir a su cuenta. Presentamos esa información alrededor de la decisión que necesita tomar: ¿en qué idiomas debería invertir a continuación?

Por el camino, exploraremos cómo traer experimentos a la dimensión del idioma de un producto. Imagine medir la frecuencia con que las personas hacen clic en un llamado a la acción cuando una página usa diferentes voces en el mismo idioma. ¿No sería eso genial? Comparar variantes ha gravitado tradicionalmente alrededor de decisiones de producto y diseño, pero los idiomas también son parte del producto.

## De cero a traducción

Una vez que ha decidido traducir un proyecto, el próximo paso es establecerlo. Como desarrollador, me disgustan procesos que vienen con mucha fricción. Acordamos que ir de cero a traducción idealmente debería tomar un paso. Ese es el nivel de experiencia para el que nos esforzamos.

La configuración normalmente implica dos cosas. Primero, extraer el contenido del repositorio para que pueda ser traducido, ya que a menudo comienzan como cadenas de texto literal en el código. Segundo, configurar el proyecto para elegir el contenido correcto basado en el idioma. Eso puede venir del dispositivo del usuario o, en casos más sofisticados, una preferencia que ha elegido.

Automatizar ello fiablemente hace unos años habría sido una pesadilla. Las cosas han cambiado, y los agentes pueden ser bastante efectivos en ello.

El proceso va así: conecta su repositorio GitHub, seleccione los idiomas en los que desea traducir, y, tras un tiempo, una solicitud de extracción se abre con los cambios. Una vez que la fusiona, las traducciones comienzan a suceder. Eso es todo.

Almacenamos las traducciones en el repositorio, junto a las comprobaciones de formato y otras validaciones que ya ejecutas como parte de [integración continua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). El pipeline de traducción alimenta los resultados de esas comprobaciones de vuelta al agente de traducción. Esto elimina una categoría completa de problemas donde una plataforma abre una solicitud de extracción y te deja tener que gestionar comprobaciones fallidas o conflictos de fusión.

Combinado con otros mecanismos para generar confianza, esto hace posible fusionar las traducciones automáticamente. Ese es el modelo en el que creemos. No tiene mucho valor pedirle a un desarrollador que verifique si una solicitud de extracción de traducción es verde y haga clic en un botón, especialmente cuando no pueden evaluar el idioma por sí mismos. Siempre hemos visto esa ceremonia extra como una señal de que el diseño podría ser mejor.

Creemos que el mejor sistema de traducción es aquel que funciona sin que tengas que pensar en ello.

## Solo traducir lo que cambió

El sistema de traducción merece su propia sección. Los tokens siguen sin ser gratis. Traducir todo siempre es lento, costoso y un desperdicio de recursos.

Para resolver eso, hemos creado un sistema de archivo de bloqueo que nos indica si algo necesita ser traducido. Llamamos a esto **traducción incremental**. La idea no es nueva: los sistemas de construcción la han utilizado durante mucho tiempo para evitar volver a compilar todo en cada compilación. Hemos adaptado la idea a los idiomas.

El sistema tiene en cuenta todo el contexto que afecta a una traducción en particular. Parte de ese contexto reside en el repositorio. Otra parte reside en Glossia y abarca varios repositorios. Construimos un árbol de dependencias y utilizamos [árboles Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos indican si las entradas de una traducción han cambiado.

El archivo de bloqueo preserva ese árbol. Puede explicar por qué algo fue enviado para traducción, o por qué no lo fue, en lugar de dejar a las personas adivinando.

Los [`L10N.md`](/docs/reference/l10n-md) archivos proporcionan contexto de localización a nuestros agentes de traducción, al igual que los `AGENTS.md` archivos proporcionan instrucciones a los agentes de codificación. Soportan un contexto más específico en directorios anidados, así como sobreescrituras de idioma a cada nivel.

Para la información que se aplica a más de un repositorio, como la terminología compartida, el servidor es la fuente de la verdad. El sistema se asegura de que utilice el contexto correcto y lo refleje en el archivo de bloqueo. Cuando ese contexto cambia, podemos mapear el cambio de vuelta a las traducciones que lo usaron y necesitan actualización.

## Generar confianza en las palabras

El sistema está diseñado para converger hacia un nivel de calidad. Para llegar a dicho estado, contamos con varias herramientas.

La primera son comprobaciones adversarias que se ejecutan después de la traducción. Piense en un compañero revisando el código que ha incluido en una solicitud de extracción. Aquí, las comprobaciones aportan conocimiento lingüístico a la revisión. Por ejemplo, una traducción no debería añadir ni quitar significado a la fuente. Eso puede ocurrir porque los modelos de lenguaje no siempre producen la misma salida con las mismas entradas.

A medida que aprendemos más de nuestros usuarios y de nuestra propia investigación sobre modelos y sistemas existentes, añadiremos más comprobaciones automatizadas al flujo. Cada una debería aumentar la confianza que pueda tener en una traducción.

La idea es llegar a un punto en el que confíes en el sistema lo suficiente para no sentir la necesidad de revisar cada solicitud de extracción. Esa confianza depende tanto del sistema como de los modelos. Podemos ayudar a seleccionar modelos basándonos en el idioma de destino, porque no todos los modelos son igualmente buenos en los mismos idiomas.

Incluso con esas comprobaciones en lugar, podría necesitar cambiar una pieza traducida. Podría ser una corrección puntual, terminología que aún no se ha incluido en el contexto, o uno de los muchos escenarios con los que todavía nos enfrentaremos.

Alguien debería poder contribuir esos cambios directamente al repositorio. Pero también creemos que el sistema debería procesar esas contribuciones como retroalimentación y sugerir cómo reconciliarlas con su contexto. Eso significaría añadir un término al glosario o ajustar la voz.

Esto es algo que una persona puede hacer de forma asíncrona, sin interrumpir la traducción continua. El sistema debería ayudarte a hacerlo más efectivo en su función aprendiendo de lo que la gente tiene que decir. Podríamos extender eso a las personas sugiriendo retroalimentación directamente desde el producto. ¿No sería eso genial?

También es necesario tener en cuenta esas correcciones para que las traducciones futuras no las sobrescriban. Una llamada de traducción sin estado no tiene conocimiento de los cambios que la gente realizó antes de ella. En los sistemas tradicionales, las memorias de traducción ayudan a cubrir ese papel. La necesidad que sirven no desaparece solo porque cambie la tecnología.

## A dónde vamos desde ahora

Esto es Glossia. Ya lo usamos para traducir Glossia, y estoy trabajando en configurarlo para traducir la documentación de Tuist, el sitio web de marketing y el panel de control a los idiomas de nuestras comunidades.

María José y yo estamos construyendo Glossia en nuestro tiempo libre, siguiendo una curiosidad que ha sido parte de nuestras conversaciones durante años.

En la programación, muchas personas están cuestionando el papel de los programadores y cómo evolucionará. Creo que la industria de localización se beneficiaría de un cuestionamiento similar de sus suposiciones y modelos. ¿Cómo podemos ayudar a nuestra industria a traducir más, más rápido y a un menor costo, sin comprometer la calidad?

No tenemos respuestas a todas las preguntas aún. Pero creemos que vamos en la dirección correcta, con la simplicidad y la atención al oficio que nos gusta verter en todo lo que hacemos.

Si esto le resuena, [hablemos](mailto:pedro@glossia.ai).
