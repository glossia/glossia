%{
  title:
    "El grafo de contexto: codificando décadas de teoría lingüística para la era de los agentes",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para generar gran contenido. Estamos diseñando un grafo dirigido y versionado para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando bastante en lo que hace la diferencia entre el contenido que suena generado por máquina y el contenido que parece escrito por alguien que entiende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve una y otra vez a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos a que esa trayectoria continúe. Aún no están del todo ahí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. Lo que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración concreta, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que estamos trabajando en Glossia, y creo que es el más interesante del espacio actualmente.

## Tres elementos, dos que controlamos

Cuando miro lo que se necesita para habilitar un enfoque verdaderamente nuevo para contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que son buenos con idiomas.** Aún no están completamente allí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo fundacional. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y ofrece todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan criterio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazarlo completamente. Pero un sistema puede facilitar su captura y reutilización.

De estos tres, hay dos que controlamos: el sistema en sí y cómo guiaremos a los usuarios para que contribuyan con contexto y nos ayuden a hacerlo mejor. Creemos que acertar con ambos es lo que hará que Glossia destaque en un espacio que se rellena rápidamente con soluciones de "solo conectar un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en las primitivas que surgen en el mundo de agentes. Y la experiencia de usuario en torno a ello es cómo aseguramos que el contexto adecuado realmente se capture, refine y se reintegre al ciclo.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no se trata de la correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre el público objetivo y el mensaje traducido debe sentirse igual que la relación entre el público original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién lee, qué marco cultural aportan y qué tono pretendía el original. Estas son exactamente las cosas que necesitan vivir en algún lugar donde un modelo pueda acceder a ellas.

## Lo que necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información debe ser capturada, y cómo estructurarla para que los agentes puedan usarla efectivamente. Cuanto más lo pensábamos, más nos dimos cuenta de que no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**.

Aquí hay trabajo previo. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [grafos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámicas, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo de múltiples agentes, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me entusiasma: **cada nodo en este grafo debe ser versionado**. Cuando cambias la voz de tu marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debería saber qué contenido se produjo bajo la definición antigua y qué piezas podrían necesitar ser revisadas. Esto nos permite optimizar el flujo de trabajo agéntico para que solo se active para las piezas que están realmente afectadas por un cambio, en lugar de volver a procesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y que debe funcionar en ambas direcciones.

Al mirarlo desde un lado: necesitas saber cómo el contenido está conectado al contexto. Cuando una pieza de contexto cambia (digamos, tu voz de marca se vuelve más casual), ¿cuáles fueron los artículos de blog, descripciones de productos o artículos de ayuda escritos bajo la versión anterior? A esos le toca volver a revisar o re-traducir. Esto es la **dirección hacia adelante, desde el contexto hacia el contenido**,

Desde el otro lado: cuando un traductor examina una pieza de contenido y se pregunta por qué se tomó una decisión, debería poder rastrearla de regreso al contexto que guió esa decisión. ¿Qué definición de voz estaba activa? ¿Qué regla terminológica se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a los humanos entender lo que hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en cualquier dirección. Es un principio de la ingeniería de sistemas, y resulta que es exactamente lo que necesitas cuando intentas crear un ciclo de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar un fragmento de contenido, ver el contexto que lo moldeó, decidir que la definición de voz necesita un ajuste, y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un ciclo ajustado, y es profundamente humano.

## Más allá de un único repositorio

Existe otra dimensión en este gráfico que encuentro particularmente interesante. **No puede residir en un solo repositorio.** El grafo de contexto debe ser compartible entre proyectos y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, en cada sitio web, en cada artículo de soporte. No reside en un solo repositorio. Es una preocupación transversal. Puedes definir tu voz central a nivel de organización y luego aplicar sobrescrituras a nivel de proyecto para un producto o una audiencia específicos. Esto es **herencia de ámbito**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto debe versionarse correctamente. No puedes simplemente cambiar la definición de voz y borrar la versión anterior. Hay mucho que aprender sobre cómo [Git gestiona el control de versiones](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mediante almacenamiento direccionable por contenido y DAGs. El modelo de Git de compromisos, ramas y diferencias se trata fundamentalmente de rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado previo. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, creemos que el cambio de voz debería producirse a través de algo a lo que estamos llamando *una solicitud de cambio de voz*. Al igual que una solicitud de código crea un espacio para debatir cambios en el código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Qué impacto tendrá eso? ¿Qué contenido se verá afectado? Estas son conversaciones valiosas para tener antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es aquí donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente promueve cuando habla de la IA, este sistema **da a los humanos un papel más creativo**.

. Imagina un equipo de lingüistas y estrategas de contenido en una sesión de traducción donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, hacer referencia al contexto cultural al que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al grafo de contexto. El sistema se encarga de la propagación.

O veámoslo un paso más: imagina sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hacíamos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿Eso no sería algo increíble?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya hacen genial: tomar decisiones matizadas y culturalmente informadas sobre el idioma. El sistema gestiona las partes mecánicas (propagación, análisis de impacto, consistencia) mientras los humanos se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía con la equivalencia dinámica. El objetivo no es una precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre lector y contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente buenos, y con las que los modelos aún luchan. El trabajo del sistema es asegurar que esos hallazgos humanos sean capturados, estructurados y reutilizables.

## Lo que sigue

En una publicación de seguimiento, profundizaremos más en lo técnico y hablaremos sobre el papel que jugarán los entornos aislados para habilitar experiencias que no se han visto en este espacio todavía, y por qué estamos invirtiendo tanto en APIs. Hay una dimensión completa en torno al entorno de pruebas, la previsualización y las pruebas de cambios lingüísticos antes de su lanzamiento que estamos emocionados de explorar.

Si algo de esto resuena con usted, ya sea que sea un lingüista frustrado con las herramientas actuales, un desarrollador que ha luchado con flujos de trabajo de localización, o simplemente alguien que piensa profundamente sobre cómo se intersectan el idioma y la tecnología, nos encantaría escuchar de usted.