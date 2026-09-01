%{
  title:
    "El grafo de contexto: codificando décadas de teoría lingüística para la era de los agentes",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para producir gran contenido. Estamos diseñando un grafo dirigido y versionado para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué hace que el contenido suene generado por máquina y el contenido que se siente escrito por alguien que entiende la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve una y otra vez a la misma cosa: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. No están completamente ahí todavía, pero el ritmo de mejora es difícil de ignorar. Sin embargo, lo que aún falta es el sistema que se interpone entre el modelo y el contenido. La cosa que le dice al modelo *quién* eres tú, *cómo* hablas, *qué* es importante en esta frase en particular, y *por qué* esa frase existe en primer lugar. Ese es el problema en el que estamos trabajando en Glossia, y creo que es el más interesante del espacio en este momento.

## Tres elementos, dos que controlamos

Cuando miró lo que se necesita para permitir un enfoque genuinamente nuevo para el contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que dominan los idiomas.** No están completamente aquí todavía, pero se están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para usarlos bien cuando lleguen allí.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Este es el piezas que se interpone entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y sirve todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede sustituir del todo eso. Pero un sistema puede hacer fácil capturarlo y reutilizarlo.

De estos tres, hay dos que controlamos: el sistema en sí, y cómo guiamos a los usuarios para contribuir contexto y ayudarnos a hacer el sistema mejor. Creemos que acertar en ambos es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente de soluciones de "simplemente conecta un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en las primitivas que están emergiendo en el mundo de agentes. Y la experiencia de usuario alrededor de ello es cómo aseguramos que el contexto correcto se capture realmente, se refine y se retroalimente en el ciclo.

Eugene Nida, uno de los fundadores de los estudios de traducción moderna, argumentó que una buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debería sentirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural traen, qué tono buscaba la original. Estos son exactamente los tipos de cosas que necesitan vivir en algún lugar al que el modelo pueda acceder.

## Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información necesita ser capturada, y cómo estructurarla para que los agentes puedan usarla de verdad. Cuanto más pensamos, más nos dimos cuenta de que esto no era un archivo de configuración plano o una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología determina cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estos pilas tienen dirección y jerarquía, y no se retroalimentan entre sí.

Existen antecedentes aquí. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, los [grafos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámicas, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias entre tareas y el flujo de información.

Pero aquí está la parte que me entusiasma: **cada nodo en este grafo debe ser versionado**. Cuando cambias la voz de tu marca, no debes perder el acceso a la versión anterior. Al actualizar una entrada de terminología, el sistema debe saber qué contenido se produjo bajo la definición anterior y qué elementos podrían necesitar ser revisados. Esto nos permite optimizar el flujo de trabajo de agentes para que solo se active para los elementos realmente afectados por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y debe funcionar en ambas direcciones.

Desde una perspectiva: necesitas saber cómo se conecta el contenido con el contexto. Cuando un elemento de contexto cambia (digamos, la voz de marca cambia para ser más coloquial), ¿qué publicaciones de blog, descripciones de producto o artículos de ayuda se escribieron bajo la versión anterior? Esos son los que deben ser revisados o retraducidos. Esto es la **dirección hacia adelante, del contexto al contenido**.

Desde el otro lado: cuando un lingüista examina un contenido y se pregunta por qué se tomó una decisión particular, debe ser capaz de rastrearlo de vuelta al contexto que guió esa decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esta **trazabilidad hacia atrás** es lo que permite a los humanos comprender lo que hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta calidad bidireccional es lo que permite la **refinación progresiva**. Un lingüista puede revisar un elemento de contenido, ver el contexto que lo moldeó, decidir que la definición de voz necesita un ajuste y aplicar esa corrección. El sistema entonces sabe exactamente qué otro contenido se ve alterado por el cambio. Es un bucle cerrado, y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este grafo que me resulta particularmente interesante. **No puede residir en un solo repositorio.** El grafo de contexto debe ser compartible entre proyectos, y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, cada sitio web y cada artículo de soporte. No reside en un solo repositorio. Es una preocupación transversal. Podrías definir tu voz principal a nivel de organización y luego aplicar sobrescritas a nivel de proyecto para un producto o audiencia específicos. Esto es **herencia de alcance**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto debe versionarse correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona el versionado](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante el almacenamiento direccionable por contenido y los DAGs. El modelo de registros, ramas y diferencias de Git se basa en rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado previo. Eso es exactamente lo que necesitamos para el contexto lingüístico.

En realidad, creemos que un cambio de voz debe ocurrir a través de algo que llamamos *solicitud de cambio de voz*. Al igual que una solicitud de extracción crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Qué impacto tendrá eso? ¿Qué contenido se verá afectado? Estas son conversaciones valiosas de tener antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es aquí donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente promueve cuando habla de la IA, este sistema **da a los humanos un papel más creativo**.

Imaginen un equipo de lingüistas y estrategas de contenido teniendo una sesión de traducción donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, hacer referencia a contextos culturales a los que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al gráfico de contexto. El sistema se encarga de la propagación.

O llevémoslo un paso más: imaginen sesiones donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Y si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo así?

**Esto no se trata de reemplazar al lingüista**. Se trata de darles mejores herramientas para hacer lo en lo que ya son expertos: tomar decisiones matizadas y culturalmente informadas sobre el lenguaje. El sistema maneja la parte mecánica (propagación, análisis de impacto, consistencia), mientras que los humanos se enfocan en la parte creativa (voz, tono, resonancia cultural).

Volvemos una y otra vez a lo que pretendía Nida con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre el lector y el contenido, independientemente del idioma. Eso requiere criterio, juicio y conciencia cultural. Cosas en las que los humanos son notoriamente buenos, y con las que los modelos aún luchan. El trabajo del sistema es asegurarse de que esos conocimientos humanos sean capturados, estructurados y reutilizables.

## ¿Qué sigue

En una publicación posterior, profundizaremos técnicamente y hablaremos sobre el papel que jugarán los entornos aislados para facilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en APIs. Hay toda una dimensión alrededor de las fases de staging, previsualización y pruebas de cambios lingüísticos antes de que estén en producción que nos encantará explorar.

Si algo de esto resuena con usted, ya sea que sea un lingüista frustrado con las herramientas actuales, un desarrollador que ha luchado con los flujos de trabajo de localización, o simplemente alguien que reflexiona profundamente sobre la intersección entre el lenguaje y la tecnología, nos encantaría escuchar su opinión.