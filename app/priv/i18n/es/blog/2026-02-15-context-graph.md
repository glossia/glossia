%{
  title: "El grafo de contexto: codificar décadas de teoría lingüística para la era de los agentes",
  summary: "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para producir contenido de calidad. Estamos diseñando un grafo dirigido y versionado para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He reflexionado mucho sobre qué marca la diferencia entre el contenido que parece generado por una máquina y el contenido que parece escrito por alguien que comprende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta siempre apunta a lo mismo: el **contexto**.

Los modelos de lenguaje son cada vez mejores con los idiomas, y apostamos por que esa evolución continúe. Aún no han alcanzado todo su potencial, pero es difícil ignorar el ritmo de mejora. Sin embargo, lo que sigue faltando es el sistema que se sitúa entre el modelo y el contenido. Aquello que indica al modelo *quién* es usted, *cómo* habla, *qué* importa en esta frase concreta y *por qué* existe esa frase. Ese es el problema en el que trabajamos en Glossia, y creo que ahora mismo es el más interesante de este ámbito.

## Tres elementos, dos bajo nuestro control

Cuando analizo qué hace falta para adoptar un enfoque realmente nuevo del contenido monolingüe y multilingüe, identifico tres elementos:

1. **Modelos que dominen los idiomas.** Aún no han alcanzado todo su potencial, pero mejoran rápidamente y apostamos por esa tendencia. No necesitamos crear un modelo fundacional. Necesitamos estar preparados para utilizarlos bien cuando alcancen ese madurez.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que recoge su voz, su terminologia, su tono y las expectativas de su audiencia, y proporciona toda esa información al agente de forma estructurada.
3. **El contexto que aportan los usuarios.** Las personas aportan criterio, sensibilidad cultural y dirección creativa. Ningún sistema puede sustituir eso por completo. Sin embargo, un sistema puede facilitar que se capture y reutilice.

De estos tres elementos, controlamos dos: el propio sistema y la forma en que orientamos a los usuarios para que aporten contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambos aspectos es lo que permitirá que Glossia destaque en un sector que se está llenando rápidamente de soluciones que se limitan a «conectar un modelo de lenguaje de gran tamaño». En el sistema debemos codificar décadas de teoría lingüística mediante las primitivas que están surgiendo en el mundo de los agentes. La experiencia de usuario que lo rodea es la que nos permite garantizar que el contexto adecuado se capture, se perfeccione y vuelva a incorporarse al ciclo.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, sostuvo que una buena traducción no consiste en establecer una correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) afirma que la relación entre la audiencia de destino y el mensaje traducido debe percibirse igual que la relación entre la audiencia original y el texto de origen. Es una idea magnífica, pero exige una comprensión profunda del contexto: quién lee, qué marco cultural aporta y qué tono pretendía transmitir el original. Este es exactamente el tipo de información que debe almacenarse en un lugar al que pueda acceder un modelo.

## Qué necesitamos capturar y cómo hacerlo

Una de las primeras cuestiones que hemos explorado es qué información debe capturarse y cómo estructurarla para que los agentes puedan utilizarla de verdad. Cuanto más lo analizábamos, más evidente resultaba que no podía tratarse de un archivo de configuración plano ni de una página de ajustes. Tenía que ser un grafo. En concreto, un **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un grafo acíclico dirigido? Porque **el contexto no es plano**. La voz de su marca influye en su terminologia. Su terminologia determina cómo escribe sobre funciones específicas. Las expectativas de su audiencia establecen el nivel de formalidad, que a su vez afecta a la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no forman ciclos.

Hay precedentes. Los grafos de conocimiento se han utilizado durante años en sistemas de inteligencia artificial para representar relaciones estructuradas entre conceptos. Más recientemente, los [grafos de contexto](https://grokipedia.com/page/context-graph) han ampliado esa idea al añadir capas de contexto dinámicas, justo lo que los agentes necesitan para tomar decisiones fundamentadas. Y en el ámbito de los sistemas multiagente, los [grafos acíclicos dirigidos se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar las dependencias entre tareas y el flujo de información.

Pero esta es la parte que me entusiasma: **cada nodo de este grafo debe tener control de versiones**. Cuando cambie la voz de su marca, no debería perder el acceso a la versión anterior. Cuando actualice una entrada de terminologia, el sistema debería saber qué contenido se produjo con la definición anterior y qué elementos podrían requerir una revisión. Esto nos permite optimizar el flujo de trabajo con agentes para que solo se active en los elementos realmente afectados por un cambio, en lugar de volver a procesarlo todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y funcionar en ambos sentidos.

Desde un lado, necesita saber cómo está conectado el contenido con el contexto. Cuando cambia una parte del contexto, por ejemplo, cuando la voz de su marca adopta un tono más informal, ¿qué entradas de blog, descripciones de productos o artículos de ayuda se redactaron con la versión anterior? Esos son los que deben revisarse o volver a traducirse. Esta es la **dirección de ida, del contexto al contenido**.

Desde el otro lado, cuando un lingüista examina una pieza de contenido y se pregunta por qué se tomó una decisión concreta, debería poder rastrearla hasta el contexto que orientó esa decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminologia se aplicó? Esta **trazabilidad inversa** permite que las personas comprendan lo que hicieron los agentes y lo mejoren con confianza.

La [Administración Nacional de Aeronáutica y el Espacio (NASA) denomina a esto trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en cualquier dirección. Es un principio de la ingeniería de sistemas y resulta ser exactamente lo necesario para crear un ciclo de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace posible el **refinamiento progresivo**. Un lingüista puede revisar una pieza de contenido, consultar el contexto que le dio forma, decidir que la definición de voz necesita un ajuste y efectuarlo. El sistema sabe entonces exactamente qué otros contenidos se ven afectados por el cambio. Es un ciclo estrecho y profundamente humano.

## Más allá de un único repositorio

Este grafo tiene otra dimensión que me parece especialmente interesante. **No puede residir en un único repositorio.** El grafo de contexto debe poder compartirse entre proyectos y, potencialmente, entre organizaciones.

Piénselo: una empresa tiene una voz de marca. Esa voz se aplica a todos los productos, sitios web y artículos de soporte. No reside en un solo repositorio. Es un aspecto transversal. Puede definir la voz principal en el ámbito de la organización y aplicar después ajustes específicos en el ámbito del proyecto para un producto o público concreto. Esto es **herencia de ámbito**, el mismo patrón que utilizamos en programación, pero aplicado al contexto lingüístico.

Además, este contexto debe tener un control de versiones adecuado. No puede limitarse a cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona las versiones](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante el almacenamiento direccionable por contenido y los grafos acíclicos dirigidos. El modelo de confirmaciones, ramas y diferencias de Git consiste, en esencia, en registrar cómo cambian las cosas con el tiempo y conservar el acceso a todos los estados anteriores. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, creemos que un cambio de voz debería realizarse mediante lo que llamamos una *solicitud de cambio de voz*. Al igual que una solicitud de incorporación de cambios crea un espacio para debatir modificaciones del código, una solicitud de cambio de voz crea un espacio para debatir cambios lingüísticos. ¿Por qué estamos adoptando un tono más conversacional? ¿Qué impacto tendrá? ¿Qué contenido se verá afectado? Son conversaciones que conviene mantener antes de que el cambio se propague.

## Donde las personas se vuelven más creativas, no menos relevantes

Y aquí es donde todo empieza a ponerse realmente interesante. En lugar de prescindir de las personas, como plantea gran parte del discurso sobre la inteligencia artificial, este sistema **les otorga un papel más creativo**.

Imagine un equipo de lingüistas y estrategas de contenidos reunido en una sesión para debatir ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, analizar cambios de tono y aportar un contexto cultural al que ningún modelo tiene acceso. Después, en lugar de actualizar manualmente cientos de archivos, plasmarían sus decisiones como ajustes en el grafo de contexto. El sistema se encargaría de propagarlos.

O vayamos un paso más allá: imagine sesiones con agentes en las que un lingüista trabaja con un asistente de inteligencia artificial para explorar ideas lingüísticas. «¿Qué ocurriría si hiciéramos que los mensajes de error fueran más empáticos?». El agente simula el impacto, muestra cómo cambiaría el contexto actual y ofrece una vista previa del contenido actualizado. El lingüista refina y ajusta la propuesta y, cuando está conforme, presenta una solicitud de cambio de contexto. ¿No sería extraordinario?

**No se trata de sustituir al lingüista.** Se trata de ofrecerle mejores herramientas para hacer aquello en lo que ya destaca: tomar decisiones lingüísticas con matices y fundamento cultural. El sistema se ocupa de los aspectos mecánicos (propagación, análisis de impacto y coherencia), mientras que las personas se centran en los aspectos creativos (voz, tono y resonancia cultural).

Siempre vuelvo a lo que Nida planteaba con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación percibida entre el lector y el contenido, independientemente del idioma. Esto exige criterio, sensibilidad y conocimiento cultural. Son cualidades en las que las personas destacan y con las que los modelos todavía tienen dificultades. La función del sistema es garantizar que esos conocimientos humanos se registren, estructuren y puedan reutilizarse.

## Próximos pasos

En una próxima publicación, profundizaremos en los aspectos técnicos y hablaremos del papel que desempeñarán los entornos aislados para posibilitar experiencias inéditas en este ámbito, así como de los motivos por los que estamos invirtiendo de forma significativa en interfaces de programación de aplicaciones. Nos entusiasma explorar toda una dimensión relacionada con la preparación, la vista previa y la prueba de cambios lingüísticos antes de publicarlos.

Si alguna de estas ideas le resulta familiar, tanto si es lingüista y siente frustración con las herramientas actuales, como si es desarrollador y ha tenido dificultades con los flujos de trabajo de localización, o simplemente reflexiona sobre la intersección entre el lenguaje y la tecnología, nos gustaría conocer su opinión.