%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agéntica",
  summary: "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para generar contenido de alta calidad. Estamos diseñando un grafo dirigido y versionado para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué diferencia el contenido que suena generado por máquina del contenido que parece escrito por alguien que comprende la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta siempre vuelve a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. Todavía no están del todo ahí, pero el ritmo de mejora es difícil de ignorar. Lo que aún falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. La parte que le indica al modelo *quién* eres, *cómo* hablas, *qué* es importante en esta frase en particular, y *por qué* esa frase existe en primer lugar. Ese es el problema en el que trabajamos en Glossia, y creo que es el más interesante del espacio ahora mismo.

## Tres elementos, dos que controlamos

Cuando miro lo que se necesita para habilitar un enfoque verdaderamente nuevo de contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que son buenos en idiomas.** Todavía no están del todo ahí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que los agentes necesitan.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y sirve todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazarlo por completo. Pero un sistema puede hacerlo fácil de capturar y reutilizar.

De estos tres, hay dos que controlamos: el sistema mismo y cómo guiamos a los usuarios para contribuir con contexto y ayudarnos a mejorar el sistema. Creemos que acertar con ambos es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente con soluciones de "solo conéctate a un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en las primitivas que emergen en el mundo de los agentes. Y la experiencia de usuario asociada es cómo nos aseguramos de que el contexto correcto se capture de verdad, se refine y se reintroduzca en el ciclo.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que una buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debe sentirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere un profundo entendimiento contextual: quién lee, qué marco cultural aporta, qué tono buscaba el original. Estos son exactamente los conceptos que necesitan residir en algún lugar donde un modelo pueda acceder a ellos.

## Qué necesitamos capturar y cómo

Uno de los primeros elementos que hemos estado explorando es qué información necesita ser capturada y cómo estructurarla para que los agentes puedan realmente usarla. Cuanto más lo pensamos, más nos dimos cuenta de que esto no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. La voz de tu marca influye en tu terminología. Tu terminología da forma a cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no retornan a sí mismas.

Hay antecedentes aquí. Los gráficos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámicas, exactamente el tipo de cosa que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me entusiasmaba: **cada nodo en este gráfico necesita estar versionado**. Cuando cambias tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debería saber qué contenido se produjo bajo la definición antigua y qué fragmentos podrían necesitar ser revisados. Esto es lo que nos permite optimizar el flujo de trabajo agéntico para que solo se active para las piezas que realmente se ven afectadas por un cambio, en lugar de repetir todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional, y debe funcionar en ambos sentidos.

Al mirarlo desde un lado: necesitas saber cómo está conectado el contenido con el contexto. Cuando una pieza de contexto cambia (digamos, tu voz de marca se hace más casual), ¿qué publicaciones de blog, descripciones de productos o artículos de ayuda se escribieron bajo la versión anterior? Esos son los que necesitas revisar o retraducir. Esta es la **dirección hacia adelante, desde el contexto hacia el contenido**.

Desde el otro lado: cuando un lingüista observa una pieza de contenido y se pregunta por qué se tomó una decisión específica, debería poder rastrearla de vuelta hacia el contexto que guió la decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esta **trazabilidad hacia atrás** es lo que permite a los humanos entender qué hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en cualquier dirección. Es un principio de la ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta calidad bidireccional es lo que hace posible el **refinamiento progresivo**. Un lingüista puede revisar una pieza de contenido, ver el contexto que la dio forma, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle ajustado y es profundamente humano.

## Más allá de un repositorio único

Hay otra dimensión en este gráfico que encuentro particularmente interesante. **No puede residir en un único repositorio.** El gráfico de contexto necesita ser compartible entre proyectos, y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica a cada producto, cada sitio web, cada artículo de soporte. No vive en un solo repositorio; es una preocupación transversal. Podrías definir tu voz central a nivel de organización, luego aplicar sobrescrituras a nivel de proyecto para un producto o público específico. Esto es **herencia de alcance**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita estar versionado correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona el versionado](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través del almacenamiento direccionable por contenido y los DAGs. El modelo de commits, ramas y diffs de Git consiste fundamentalmente en rastrear cómo cambian las cosas a lo largo del tiempo, preservando el acceso a cada estado anterior. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debería ocurrir a través de algo a lo que estamos llamando una *solicitud de cambio de voz*. Al igual que una pull request crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos pasando a un tono más conversacional? ¿Cuál será el impacto? ¿Qué contenido se verá afectado? Estas son conversaciones valiosas antes de que el cambio se propague.

## ¿Dónde los humanos se vuelven más creativos, no menos relevantes

Y aquí es donde las cosas empiezan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente impulsa cuando hablan de IA, este sistema **da a los humanos un rol más creativo**.

Imagina un equipo de lingüistas y estrategas de contenidos teniendo una sesión donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, hacer referencia a contextos culturales a los que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al grafo de contexto. El sistema se encarga de la propagación.

O lleva el asunto un paso más allá: imagina sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Y si hacemos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría parecer el contenido actualizado. El lingüista refina, ajusta, y cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería esto algo notable?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya hacen excelente: tomar decisiones matizadas y culturalmente informadas sobre el lenguaje. El sistema maneja las partes mecánicas (propagación, análisis de impacto, coherencia) mientras los humanos se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida intentaba con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente hábiles, y en las que los modelos aún luchan. La función del sistema es asegurarse de que esas percepciones humanas sean capturadas, estructuradas y reutilizables.

## ¿Qué sigue

En una publicación de seguimiento, seremos más técnicos y hablaremos sobre el rol que los entornos aislados tendrán para habilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en APIs. Hay una dimensión completa en torno a entornos de staging, previsualización y pruebas de cambios lingüísticos antes de lanzarlos a producción que nos emociona profundizar.

Si esto resuena contigo, ya seas un lingüista frustrado con las herramientas actuales, un desarrollador que haya luchado con los flujos de trabajo de localización, o simplemente alguien que reflexiona en profundidad sobre cómo el lenguaje y la tecnología se intersecan, nos encantaría escuchar de ti.