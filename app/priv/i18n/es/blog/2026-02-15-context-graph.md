%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agéntica",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para generar gran contenido. Estamos diseñando un grafo dirigido y versionado para capturar conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué hace la diferencia entre el contenido que suena generado por máquina y el contenido que se siente escrito por alguien que entiende al público, la marca y los matices culturales detrás de cada palabra. La respuesta vuelve una y otra vez a la misma cosa: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos a que esa trayectoria continúe. Todavía no están completamente ahí, pero el ritmo de mejora es difícil de ignorar. Lo que aún falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. La cosa que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración en particular, y *por qué* que esa oración existe en primer lugar. Ese es el problema en el que trabajamos en Glossia, y creo que es el más interesante del sector ahora mismo.

## Tres elementos, dos que controlamos

Cuando miro qué se necesita para habilitar un enfoque genuinamente nuevo para contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que funcionen bien con idiomas.** Aún no están completamente allí, pero mejoran rápido y apostamos por esa tendencia. No necesitamos construir un modelo fundacional. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia, y ofrece todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los seres humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazar eso por completo. Pero un sistema puede facilitar su captura y reutilización.

De estos tres, hay dos que controlamos: el propio sistema, y la forma en que guiamos a los usuarios para que contribuyan con contexto y ayuden a mejorar el sistema. Creemos que lograr ambas cosas correctamente es lo que hará destacar a Glossia en un espacio que rápidamente está llenándose de soluciones de "simplemente conecta un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en las primitivas que están emergiendo en el mundo agencial. Y la experiencia de usuario que lo rodea es cómo aseguramos que el contexto correcto realmente se capture, se refine y se reintegre en el bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debería sentirse igual que la relación entre la audiencia original y la fuente. Esa es una idea hermosa, pero requiere una comprensión contextual profunda: quién lee, qué marco cultural traen consigo, qué tono buscaba el original. Estas son exactamente el tipo de cosas que deben permanecer en algún lugar donde un modelo pueda acceder a ellas.

## ¿Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información necesita ser capturada, y cómo estructurarla para que los agentes puedan usarla efectivamente. Cuanto más pensamos en ello, más nos dimos cuenta de que no era un archivo de configuración plano o una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**.

Aquí hay antecedentes. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea agregando capas de contexto dinámicas, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero esta es la parte que me entusia: **cada nodo en este grafo necesita ser versionado**. Cuando cambias tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debe saber qué contenido se generó bajo la definición anterior y qué elementos podrían necesitar revisión. Esto nos permite optimizar el flujo de trabajo de agentes para que solo se dispare en los elementos realmente afectados por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y debe funcionar en ambas direcciones.

Mirándolo desde un lado: necesitas saber cómo el contenido está conectado al contexto. Cuando un elemento de contexto cambia (digamos, tu voz de marca se vuelve más casual), ¿qué entradas de blog, descripciones de productos o artículos de ayuda fueron escritos bajo la versión anterior? Esos son los que necesitan ser revisados o retradujs. Esto es el **dirección hacia adelante, desde el contexto hacia el contenido**.

Desde el otro lado: cuando un traductor examina un elemento de contenido y se pregunta por qué se tomó una decisión particular, debe poder rastrear de vuelta al contexto que guió la decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a las personas comprender qué hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [rastreo bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de la ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar una pieza de contenido, ver el contexto que lo moldeó, decidir que la definición de voz necesita un ajuste y crear ese ajuste. El sistema luego sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle cerrado y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este grafo que encuentro particularmente interesante. **No puede vivir en un único repositorio.** El gráfico de contexto debe ser compartible entre proyectos y, potencialmente, entre organizaciones.

Pensándolo bien: una empresa tiene una voz de marca. Esa voz se aplica a través de cada producto, cada sitio web, cada artículo de soporte. No vive en un solo repositorio. Es una preocupación transversal. Podrías definir tu voz principal a nivel de organización, luego aplicar sobrescrituras a nivel de proyecto para un producto o una audiencia específica. Esto es **herencia de ámbito**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita ser versionado correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho por aprender sobre cómo [Git gestiona el control de versiones](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través del almacenamiento direccionable por contenido y los DAGs. El modelo de Git de revisiones, ramas y diferencias es fundamentalmente sobre rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado anterior. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, creemos que el cambio de voz debería ocurrir a través de algo al que llamamos *solicitud de cambio de voz*. Así como una Pull Request crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos pasando a un tono más conversacional? ¿Cuál será el impacto? ¿Qué contenido se verá afectado? Son conversaciones que valen la pena antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es aquí donde las cosas se ponen realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente empuja cuando habla de la IA, el sistema **da a los humanos un papel más creativo**.

Imaginen un equipo de lingüistas y estrategas de contenido teniendo una sesión de traducción donde discutan ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, referirse a un contexto cultural del que no tiene acceso ningún modelo. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al gráfico de contexto. El sistema se encarga de la propagación.

Tómalo un paso más: imagina sesiones con agentes donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, presenta una solicitud de cambio de contexto. ¿No sería algo increíble?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer algo en lo que son ya excelentes: tomar decisiones lingüísticas matizadas y culturalmente informadas. El sistema gestiona las partes mecánicas (propagación, análisis de impacto, consistencia) mientras las personas se centran en las partes creativas (voz, tono, resonancia cultural).

Vuelvo una y otra vez a qué se refería Nida con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, criterio y conciencia cultural. Cosas en las que las personas son notablemente hábiles y con las que los modelos aún luchan. El propósito del sistema es asegurarse de que esas perspectivas humanas sean capturadas, estructuradas y reutilizables.

## ¿Qué sigue?

En una publicación posterior, profundizaremos y hablaremos sobre el papel que jugarán los entornos aislados en habilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en APIs. Hay toda una dimensión alrededor del entorno de pruebas, la previsualización y la prueba de cambios lingüísticos antes de ir a producción que estamos emocionados de explorar.

Si esto resuena contigo, ya sean lingüistas frustrados con las herramientas actuales, desarrolladores que han luchado con los flujos de trabajo de localización, o simplemente alguien que piensa profundamente sobre cómo se intersectan el lenguaje y la tecnología, nos encantaría escuchar de ti.