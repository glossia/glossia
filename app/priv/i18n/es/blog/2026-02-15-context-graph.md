%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agencial",
  summary:
    "Los modelos de lenguaje son potentes pero necesitan el contexto adecuado para producir contenido de gran calidad. Estamos diseñando un grafo versionado y dirigido para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué hace que haya una diferencia entre el contenido que suena generado por máquina y el contenido que parece escrito por alguien que comprende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve una y otra vez a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. Aún no están del todo allí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. Lo que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración particular, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que trabajamos en Glossia, y creo que es el más interesante del sector actualmente.

## Tres elementos, dos que controlamos

Al mirar lo necesario para habilitar un enfoque verdaderamente nuevo sobre contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que funcionan bien con idiomas.** Aún no están completamente ahí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para utilizarlos bien cuando lleguen ahí.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, tus expectativas de audiencia y lo entrega al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazarlo completamente. Pero un sistema puede hacer fácil capturar y reutilizar.

De estos tres, hay dos que controlamos: el propio sistema, y cómo guiamos a los usuarios para contribuir con contexto y ayudarnos a mejorar el sistema. Creemos que acertar en ambos aspectos es lo que hará que Glossia destaque en un espacio que se llena rápidamente con soluciones de "solo conectar un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos que están emergiendo en el mundo de los agentes. Y la experiencia de usuario a su alrededor es cómo aseguramos que el contexto correcto realmente se capture, refine y se alimente de nuevo en el bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debe sentirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural aportan, qué tono pretendía el original. Estas son exactamente las cosas de este tipo que necesitan vivir donde un modelo pueda acceder a ellas.

## ¿Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información debe capturarse, y cómo estructurarla para que los agentes puedan usarla realmente. Cuanto más lo pensábamos, más nos dimos cuenta de que no se trataba de un archivo de configuración plano ni de una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología moldea cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no se retroalimentan entre sí.

Hay antecedentes previos aquí. Los grafos de conocimiento han sido utilizados durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [grafos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas dinámicas de contexto, exactamente el tipo de cosa que los agentes necesitan para tomar decisiones informadas. Y en el mundo multi-agente, [DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero esta es la parte que me entusiasma: **cada nodo en este grafo debe versionarse**. cuando cambias tu voz de marca, no debieras perder acceso a la versión anterior. cuando actualizas una entrada de terminología, el sistema debería saber qué contenido se produjo bajo la definición anterior y qué elementos podrían necesitar revisión. esto es lo que nos permite optimizar el flujo de trabajo de agentes de modo que solo se active para los elementos realmente impactados por un cambio, en lugar de volver a procesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional, y debe funcionar en ambas direcciones.

Mirándolo desde un lado: necesitas saber cómo el contenido se conecta al contexto. Cuando una pieza de contexto cambia (por ejemplo, tu voz de marca evoluciona hacia un tono más casual), ¿cuáles entradas de blog, descripciones de producto o artículos de ayuda fueron creados bajo la versión anterior? Aquellos son los que deben ser revisados o retraduccionados. Esto es la **dirección hacia adelante, desde el contexto al contenido**.

Por el otro lado: cuando un lingüista examina una pieza de contenido y se pregunta por qué se tomó una decisión particular, debería poder rastrearla al contexto que orientó dicha decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a los humanos comprender lo que hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de la ingeniería de sistemas y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar una pieza de contenido, ver el contexto que lo dio forma, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle cerrado y profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este grafo que encuentro particularmente interesante. **No puede vivir en un único repositorio.** El grafo de contexto debe ser compartible entre proyectos y, potencialmente, entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica a cada producto, cada sitio web, cada artículo de soporte. No vive en un solo repositorio. Es una preocupación transversal. Podrías definir tu voz central a nivel de organización y luego aplicar sobrescrituras a nivel de proyecto para un producto o audiencia específicas. Esto es **herencia de ámbito**el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Además, este contexto necesita ser versionado correctamente. No puedes simplemente cambiar la definición de voz y borrar la versión anterior. Hay mucho que aprender de cómo [Git gestiona el versionado](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante almacenamiento direccionable por contenido y DAGs. El modelo de commits, ramas y diferencias de Git se basa fundamentalmente en rastrear cómo cambian las cosas con el tiempo, preservando el acceso a cada estado anterior. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, creemos que un cambio de voz debería ocurrir a través de algo que estamos llamando una *solicitud de cambio de voz*. Al igual que una solicitud de extracción genera un espacio para discutir los cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Qué impacto tendrá eso? ¿Qué contenido se verá afectado? Estas son conversaciones que valen la pena tener antes de que el cambio se propague.

## Donde los humanos se vuelvan más creativos, no menos relevantes

Y es aquí donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente impulsa cuando habla de IA, este sistema **da a los humanos un rol más creativo**.

Imagina un equipo de lingüistas y estrategas de contenido en una sesión donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono y hacer referencia a un contexto cultural al que ningún modelo tiene acceso. Luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al gráfico de contexto. El sistema se encarga de la propagación.

Odate un paso más: imagina sesiones agénticas donde un lingüista colaborar con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hacemos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo increíble?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya dominan: tomar decisiones sutiles e informadas culturalmente sobre el idioma. El sistema gestiona las partes mecánicas (propagación, análisis de impacto, consistencia) mientras los humanos se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía decir con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre lector y contenido, independientemente del idioma. Eso requiere gusto, criterio y conciencia cultural. Cosas en las que los humanos son notablemente hábiles, y en las que los modelos aún luchan. El trabajo del sistema es asegurar que esas intuiciones humanas se capturen, se estructuren y sean reutilizables.

## ¿Qué sigue?

En una publicación posterior, profundizaremos en lo técnico y hablaremos del papel que jugarán los entornos aislados para habilitar experiencias que aún no hemos visto en este espacio, y por qué estamos invirtiendo fuertemente en APIs. Hay una dimensión completa alrededor del despliegue, previsualización y pruebas de cambios lingüísticos antes de que se lancen, en la que nos emocionamos por profundizar.

Si algo de esto resuena contigo, sea un lingüista frustrado con las herramientas actuales, un desarrollador que ha luchado con los flujos de trabajo de localización, o simplemente alguien que piensa profundamente sobre cómo se cruzan el idioma y la tecnología, nos encantaría escucharte.