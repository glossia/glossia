%{
  title:
    "El grafo del contexto: codificando décadas de teoría lingüística para la era de los agentes",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para producir contenido excelente. Estamos diseñando un grafo dirigido y versionado para capturar conocimiento lingüístico y compartirlo con los agentes, y creemos que esto es lo que hará que Glossia se destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué es lo que hace la diferencia entre el contenido que suena generado por máquina y el contenido que parece escrito por alguien que entiende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve siempre a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. Todavía no están completamente ahí, pero el ritmo de mejora es difícil de ignorar. Lo que aún falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. Lo que le dice al modelo *quién* eres, *how* hablas, *qué* importa en esta oración particular, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que trabajamos en Glossia, y creo que es el más interesante en el espacio ahora.

## Tres elementos, dos que controlamos

Cuando miro lo necesario para habilitar un enfoque genuinamente nuevo para contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que funcionan bien con idiomas.** Aún no están totalmente allí, pero mejoran rápido y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que los agentes necesitan.** Esta es la pieza que se encuentra entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y sirve todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazar completamente eso. Pero un sistema puede hacerlo fácil de capturar y reutilizar.

De estos tres, hay dos que controlamos: el sistema en sí y cómo guiamos a los usuarios para que contribuyan con contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambos es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente con soluciones de "solo conecta un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos que están emergiendo en el mundo de los agentes. Y la experiencia de usuario alrededor de ello es cómo aseguramos que el contexto correcto se capture realmente, se refine y se alimente de nuevo al ciclo.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que una buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debería sentirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural traen y qué tono estaba buscando el original. Esos son exactamente los tipos de cosas que necesitan existir en un lugar donde un modelo pueda acceder a ellas.

## Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información necesita ser capturada, y cómo estructurarla para que los agentes puedan utilizarla de verdad. Cuanto más pensamos en ello, más nos damos cuenta de que no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología moldea cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no vuelven a sí mismas.

Ya existen antecedentes aquí. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [grafos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámico, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [Los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me entusiasma: **cada nodo en este grafo debe ser versionado**. Cuando cambias la voz de marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada terminológica, el sistema debería saber qué contenido fue producido bajo la antigua definición y qué elementos podrían requerir revisión. Esto es lo que nos permite optimizar el flujo de trabajo agéntico para que se active solo en los elementos realmente afectados por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y debe funcionar en ambas direcciones.

Al mirarlo desde un lado: necesitas saber cómo se conecta el contenido con el contexto. Cuando una pieza de contexto cambia (digamos, tu voz de marca cambia hacia ser más informal), ¿cuáles fueron los artículos de blog, descripciones de productos o artículos de ayuda escritos bajo la versión anterior? Aquellos son los que necesitan ser revisados o retraducidos. Esta es la **dirección hacia adelante, desde el contexto al contenido**.

Desde el otro lado: cuando un lingüista examina una pieza de contenido y se pregunta por qué se tomó una decisión particular, debería poder rastrearla de vuelta al contexto que guió dicha decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esta **trazabilidad hacia atrás** es lo que permite a los humanos comprender qué hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [rastreabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta calidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar un fragmento de contenido, ver el contexto que lo dio forma, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle ajustado, y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este gráfico que encuentro particularmente interesante. **No puede vivir en un solo repositorio.** El grafo de contexto debe ser compartible entre proyectos, y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica a cada producto, sitio web, artículo de soporte. No vive en un solo repositorio. Es una preocupación transversal. Podrías definir tu voz central a nivel de organización y luego aplicar sobrescrituras a nivel de proyecto para un producto o audiencia específica. Esto es **herencia de ámbito**el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita versionarse correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender sobre cómo [Git gestiona el versionado](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante almacenamiento direccionado por contenido y DAGs. El modelo de commits, ramas y diffs de Git se trata fundamentalmente de rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado anterior. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debería ocurrir a través de algo que llamamos un *solicitud de cambio de voz*.

## Al igual que un pull request crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Qué impacto tendrá? ¿Qué contenido se verá afectado? Son conversaciones valiosas para tener antes de que el cambio se propague.

Donde los humanos se vuelven más creativos, no menos relevantes **Y esto es donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente promueve cuando habla de la IA, este sistema**da a los humanos un rol más creativo

.

O llevemos esto un paso más: imaginen sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué tal si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza lo que podría parecer el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. Eso sería increíble, ¿no?

**Esto no se trata de reemplazar al lingüista.** Se trata de proporcionarles mejores herramientas para hacer lo que ya son capaces: tomar decisiones matizadas y culturalmente informadas sobre el idioma. El sistema maneja las partes mecánicas (propagación, análisis de impacto, consistencia), mientras que los humanos nos enfocamos en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía con la equivalencia dinámica. El objetivo no es la precisión lingüística en el sentido mecánico. Se trata de crear la misma relación percibida entre lector y contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son admirablemente capaces, y con las que los modelos aún luchan. El trabajo del sistema es asegurarse de que esos conocimientos humanos sean capturados, estructurados y reutilizables.

## ¿Qué sigue

En una publicación de seguimiento, seremos más técnicos y hablaremos sobre el papel que jugarán los entornos aislados al habilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en las APIs. Hay toda una dimensión en torno al ensayo, la previsualización y las pruebas de cambios lingüísticos antes de su lanzamiento que queremos profundizar.

Si algo de esto resuena contigo, ya sea un lingüista frustrado con el conjunto de herramienta actual, un desarrollador que ha luchado con los flujos de trabajo de localización, o simplemente alguien que piensa profundamente sobre cómo se cruzan el idioma y la tecnología, nos encantaría escucharte.