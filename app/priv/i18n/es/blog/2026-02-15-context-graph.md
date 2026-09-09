%{
  title:
    "El grafo de contexto: codificando décadas de teoría lingüística para la era de los agentes",
  summary:
    "Los modelos de lenguaje son poderosos, pero necesitan el contexto adecuado para producir gran contenido. Estamos diseñando un grafo versionado y dirigido para capturar conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en lo que marca la diferencia entre el contenido que suena generado por máquina y el contenido que se siente escrito por alguien que entiende la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta siempre vuelve a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y confiamos en que esa trayectoria continúe. Aun no están completamente ahí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. Lo que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración concreta, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que trabajamos en Glossia, y creo que es la más interesante del sector actualmente.

## Tres elementos, dos que controlamos.

Cuando miro lo necesario para habilitar un enfoque verdaderamente nuevo al contenido monolingual y multilingüe, veo tres elementos:

1. **Modelos que funcionan bien con idiomas.** Aún no están del todo ahí, pero están mejorando rápidamente y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y sirve todo eso al agente de una manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazar completamente eso. Pero un sistema puede hacer que sea fácil capturarlo y reutilizarlo.

De estos tres, hay dos que controlamos: el sistema en sí, y cómo guiamos a los usuarios para que contribuyan con contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambos es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente con soluciones de "solo conecta un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos emergentes del mundo de los agentes. Y la experiencia de usuario que lo rodea es cómo aseguramos que el contexto correcto se capture realmente, se refine y se reintroduzca al bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debe sentirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural traen, qué tono intentaba el original. Esas son exactamente las cosas que necesitan vivir en algún lugar donde un modelo pueda acceder a ellas.

## Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información necesita ser capturada, y cómo estructurarla para que los agentes puedan utilizarla efectivamente. Cuanto más pensamos en ello, más nos dimos cuenta de que no era un archivo de configuración plano ni una página de ajustes. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología moldea cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no se retroalimentan.

Hay antecedentes aquí. Los gráficos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámicas, exactamente el tipo de cosa que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar las dependencias de tareas y el flujo de información.

Pero aquí está la parte que me entusiasm: **cada nodo en este gráfico necesita ser versionado**. Cuando cambias la voz de tu marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debe saber qué contenido se produjo bajo la definición anterior y qué piezas pueden necesitar ser repasadas. Esto es lo que nos permite optimizar el flujo de trabajo de agentes para que solo se active para las piezas que están realmente afectadas por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y funcionar en ambos sentidos.

Mirándolo desde un lado: necesitas saber cómo está conectado el contenido al contexto. Cuando cambia una pieza de contexto (por ejemplo, tu voz de marca se vuelve más casual), ¿qué publicaciones de blog, descripciones de producto o artículos de ayuda se redactaron bajo la versión anterior? Esos son los que necesitan ser revisados o retraducidos. Este es el **dirección hacia adelante, del contexto al contenido**.

Desde el otro lado: cuando un lingüista revisa una pieza de contenido y pregunta por qué se tomó una decisión específica, debe poder rastrearla de vuelta al contexto que guió esa decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Este **retrotrazabilidad** es lo que permite a los humanos comprender lo que hicieron los agentes y iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de la ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta calidad bidireccional es lo que hace posible **refinamiento progresivo** posible. Un lingüista puede revisar un fragmento de contenido, ver el contexto que lo moldeó, decidir que la definición de la voz necesita ajuste, y crear ese ajuste. El sistema entonces conoce exactamente qué otro contenido se ve afectado por el cambio. Es un bucle ajustado, y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este grafo que encuentro particularmente interesante. **No puede vivir en un único repositorio.** El gráfico de contexto necesita ser compartible entre proyectos, y potencialmente entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, cada sitio web, cada artículo de soporte. No reside en un repositorio. Es una preocupación transversal. Podrías definir tu voz central a nivel de organización, luego aplicar sobrescritas a nivel de proyecto para un producto o audiencia específica. Esto es **herencia de alcance**, el mismo patrón al que estamos acostumbrados en la programación, pero aplicado al contexto lingüístico.

Y este contexto necesita ser versionado correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender sobre cómo [Git gestiona el versionado](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través de almacenamiento direccionable por contenido y DAGs. El modelo de commits, ramas y diffs en Git se trata fundamentalmente de rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado previo. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debería ocurrir a través de algo que llamamos un *solicitud de cambio de voz*. Algo así como una solicitud de extracción crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando hacia un tono más conversacional? ¿Cuál será el impacto? ¿Qué contenido se verá afectado? Estas son conversaciones que vale la pena tener antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y aquí es donde las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que muchas personas promueven cuando hablan de IA, este sistema **da a los humanos un rol más creativo**.

Imaginen a un equipo de lingüistas y estrategas de contenido teniendo una sesión de traducción donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, hacer referencia al contexto cultural que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al grafo de contexto. El sistema se encarga de la propagación.

O llevemos esto un paso más: imaginemos sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. \\"¿Qué pasaría si hacemos los mensajes de error más empáticos?\\" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya son excelentes: tomar decisiones lingüísticas matizadas e informadas culturalmente. El sistema maneja las partes mecánicas (propagación, análisis de impacto, consistencia) mientras los humanos se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida quería decir con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente hábiles y con las que los modelos aún luchan. El trabajo del sistema es asegurarse de que esas perspectivas humanas se capturen, se estructuren y sean reutilizables.

## ¿Qué sigue?

En una publicación posterior, abordaremos aspectos más técnicos y hablaremos del papel que jugarán los entornos aislados al habilitar experiencias que aún no se han visto en este espacio y por qué estamos invirtiendo fuertemente en APIs. Existe toda una dimensión en torno al staging, la previsualización y las pruebas de cambios lingüísticos antes de su lanzamiento que nos enorgullece explorar.

Si esto resuena con usted, ya sea un lingüista frustrado con las herramientas actuales, un desarrollador que haya luchado con los flujos de localización, o simplemente alguien que piense profundamente sobre cómo se intersecta el lenguaje y la tecnología, nos encantaría escucharles.