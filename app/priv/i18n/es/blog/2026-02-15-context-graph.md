%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agéntica",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para generar excelente contenido. Estamos diseñando un grafo versionado y dirigido para capturar conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho sobre lo que marca la diferencia entre el contenido que suena generado por máquina y el contenido que da la sensación de haber sido escrito por alguien que entiende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve una y otra vez a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. Aún no están del todo allí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se ubica entre el modelo y el contenido. Lo que le indica al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración en particular, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que estamos trabajando en Glossia, y creo que es el más interesante del ámbito por ahora.

## Tres elementos, dos que controlamos

Cuando miro lo necesario para habilitar genuinamente un nuevo enfoque para contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que son buenos para los idiomas.** Aún no están completamente ahí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo fundacional. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y te sirve a ti al agente de una manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede sustituirlo completamente. Pero un sistema puede facilitar su captura y reutilización.

De estos tres, hay dos que controlamos: el sistema en sí, y cómo guiamos a los usuarios para que aporten contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambos es lo que hará que Glossia destaque en un espacio que se llena rápidamente con soluciones de "solo conectar una LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos que están emergiendo en el mundo agéntico. Y la experiencia de usuario a su alrededor es cómo aseguramos que el contexto adecuado realmente se capture, se refine y se retroalimente en el bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) , dice que la relación entre la audiencia objetivo y el mensaje traducido debería sentirse igual que la relación entre la audiencia original y la fuente. Esa es una idea hermosa, pero requiere una comprensión profunda del contexto: quién está leyendo, qué marco cultural traen, qué tono buscaba el original. Estas son exactamente las cosas que necesitan estar en algún lugar al que un modelo pueda acceder.

## Lo que necesitamos capturar, y cómo

Una de las primeras cosas en las que hemos estado explorando es qué información necesita ser capturada y cómo estructurarla para que los agentes puedan utilizarla realmente. Cuanto más lo pensábamos, más nos dimos cuenta de que esto no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología da forma a cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no vuelven sobre sí mismas.

Aquí hay antecedentes. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [grafos de contexto](https://grokipedia.com/page/context-graph) han ampliado esa ideia agregando capas de contexto dinámicas, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo de los agentes múltiples, [Los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar las dependencias de las tareas y el flujo de información.

Pero esta es la parte que me motiva: **cada nodo de este grafo necesita estar versionado**. Cuando cambies tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualices una entrada de terminología, el sistema debe saber qué contenido se produjo bajo la definición antigua y qué partes podrían necesitar ser repasadas. Esto es lo que nos permite optimizar el flujo de trabajo de los agentes para que solo se active para las partes que realmente se ven afectadas por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y debe funcionar en ambos sentidos.

Al mirarlo desde un lado: necesitas saber cómo se conecta el contenido con el contexto. Cuando una pieza de contexto cambia (digamos, tu voz de marca se vuelve más casual), ¿qué publicaciones de blog, descripciones de producto o artículos de ayuda fueron escritos bajo la versión anterior? Esos son los que necesitan ser revisados o retraducidos. Esto es la **dirección hacia adelante, desde el contexto al contenido**,

Desde el otro lado: cuando un lingüista examina una pieza de contenido y se pregunta por qué se tomó una decisión en particular, debe ser capaz de rastrearla de vuelta al contexto que la guió. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a los humanos entender lo que los agentes hicieron e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en cualquier dirección. Es un principio de ingeniería de sistemas, y resulta que es exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar una pieza de contenido, ver el contexto que la dio forma, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle cerrado y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este gráfico que encuentro particularmente interesante. **No puede vivir en un único repositorio.** El grafo de contexto debe ser compartible entre proyectos y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, en cada sitio web, en cada artículo de soporte. No vive en un único repositorio. Es una preocupación transversal. Podrías definir tu voz principal a nivel de organización y luego aplicar sobrescrituras a nivel de proyecto para un producto o audiencia específico. Esto es **herencia de ámbito**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto debe versionarse adecuadamente. No puedes simplemente cambiar la definición de la voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona el versionamiento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante almacenamiento direccionable por contenido y DAGs. El modelo de Git de comits, ramas y diferencias es fundamentalmente sobre rastrear cómo cambian las cosas a lo largo del tiempo, preservando el acceso a cada estado previo. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debería ocurrir a través de algo al que llamamos una *solicitud de cambio de voz*. Al igual que una solicitud de extracción crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos adoptando un tono más conversacional? ¿Qué impacto tendrá eso? ¿Qué contenido se verá afectado? Son conversaciones valiosas por llevar a cabo antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es aquí donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar humanos, que es la narrativa que mucha gente empuja cuando habla de la IA, este sistema **da a los humanos un rol más creativo**.

Imagina un equipo de lingüistas y estrategas de contenido teniendo una sesión donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, hacer referencia a un contexto cultural al que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al gráfico de contexto. El sistema se encarga de la propagación.

O llevemos un paso más: imagina sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Y si hacemos que los mensajes de error sean más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo así?

**No se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya saben hacer bien: tomar decisiones con matices, informadas culturalmente, sobre el lenguaje. El sistema maneja las partes mecánicas (propagación, análisis de impacto, consistencia) mientras las personas se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma sensación de vínculo entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente buenos, y con las que los modelos aún luchan. El trabajo del sistema es asegurarse de que esos aportes humanos se capturen, se estructuren y sean reutilizables.

## ¿Qué sigue?

En una publicación de seguimiento, seremos más técnicos y hablaremos del papel que jugarán los entornos aislados para habilitar experiencias que aún no hemos visto en este ámbito, y por qué estamos invirtiendo fuertemente en las APIs. Existe toda una dimensión en torno a la puesta en fase, la previsualización y la prueba de cambios lingüísticos antes de su lanzamiento que nos encantaría explorar.

Si esto resuena con ustedes, ya sean lingüistas frustrados con las herramientas actuales, desarrolladores que han luchado con los flujos de trabajo de localización, o simplemente personas que piensan profundamente sobre cómo se cruzan el lenguaje y la tecnología, nos encantaría escuchar de ustedes.