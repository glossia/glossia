%{
  title:
    "El grafo de contexto: codificando décadas de teoría lingüística para la era de los agentes",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para generar gran contenido. Estamos diseñando un grafo dirigido y versionado para capturar conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en lo que marca la diferencia entre el contenido que suena generado por máquina y el contenido que parece haber sido escrito por alguien que entiende a la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta siempre regresa al mismo punto: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos por que esa trayectoria continúe. Aún no están completamente ahí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se encuentra entre el modelo y el contenido. Lo que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración concreta, y *por qué* esa oración existe en primer lugar. Ese es el problema en el que estamos trabajando en Glossia, y creo que es el más interesante del sector actualmente.

## Tres elementos, dos que controlamos

Cuando miro lo necesario para habilitar un enfoque genuinamente nuevo de contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que dominan los idiomas.** Aún no están completamente ahí, pero mejoran rápido y apostamos por esa tendencia. No necesitamos construir un modelo fundacional. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, tus expectativas de audiencia y entrega todo eso al agente de manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan juicio, conciencia cultural y dirección creativa. No hay ningún sistema que pueda reemplazar completamente eso. Pero un sistema puede hacer que sea fácil capturar y reutilizar.

De estas tres, hay dos que controlamos: el sistema en sí mismo, y cómo guiamos a los usuarios para que aporten contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambas es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente de soluciones "solo conectar un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos que están emergiendo en el mundo de los agentes. Y la experiencia de usuario alrededor es cómo aseguramos que el contexto correcto se capture, refine y retroalimente al bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que una buena traducción no se trata de la correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) afirma que la relación entre el público objetivo y el mensaje traducido debe sentirse igual que la relación entre el público original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural traen, qué tono pretendía el original. Estas son exactamente las cosas que necesitan estar en algún lugar donde un modelo pueda acceder a ellas.

## Qué necesitamos capturar, y cómo

Una de las primeras cosas que hemos estado explorando es qué información debe capturarse y cómo estructurarla para que los agentes puedan realmente utilizarla. Cuanto más pensábamos en ello, más nos dimos cuenta de que esto no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología da forma a cómo escribes sobre características específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no crean ciclos sobre sí mismas.

Aquí hay antecedentes. Los gráficos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas dinámicas de contexto, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo multiagente, [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me emociona: **cada nodo en este gráfico necesita ser versionado**. Cuando cambies tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualices una entrada de terminología, el sistema debería saber qué contenido se produjo bajo la definición antigua y qué piezas podrían necesitar ser revisadas. Esto es lo que nos permite optimizar el flujo de trabajo de agentes para que solo se active para las piezas que realmente se ven afectadas por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional, y debe funcionar en ambas direcciones.

Mirando desde un lado: necesitas saber cómo el contenido está conectado al contexto. Cuando una pieza de contexto cambia (por ejemplo, cuando tu voz de marca se vuelve más casual), ¿qué publicaciones de blog, descripciones de productos o artículos de ayuda se escribieron bajo la versión anterior? Son esas las que necesitan ser revisadas o retraducidas. Esto es la **dirección hacia adelante, desde el contexto al contenido**.

Desde el otro lado: cuando un traductor examina una pieza de contenido y se pregunta por qué se tomó una decisión particular, debería poder rastrearla de vuelta al contexto que guió la decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a las personas entender qué hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en ambas direcciones. Es un principio de ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar una pieza de contenido, ver el contexto que la moldeó, decidir que la definición de voz necesita un ajuste y crear ese ajuste. El sistema luego sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle cerrado y es profundamente humano.

## Más allá de un único repositorio

Hay otra dimensión en este grafo que encuentro particularmente interesante. **No puede vivir en un solo repositorio.** El grafo de contexto debe ser compartible entre proyectos, y potencialmente entre organizaciones.

Pénsalo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, cada sitio web, cada artículo de soporte. No vive en un único repositorio. Es una preocupación transversal. Podrías definir tu voz principal a nivel de organización, y luego aplicar sobrescrituras a nivel de proyecto para un producto o público específico. Esto es **herencia de ámbito**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita ser versionado correctamente. No puedes simplemente cambiar la definición de voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona las versiones](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través de almacenamiento dirigido por contenido y DAGs. El modelo de Git con commits, ramas y diferencias se trata fundamentalmente de rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado anterior. Es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debería ocurrir a través de algo que llamamos una *solicitud de cambio de voz*. Al igual que un pull request crea un espacio para discutir cambios de código, una solicitud de cambio de voz crea un espacio para debatir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Qué impacto tendrá eso? ¿Qué contenido se verá afectado? Estas son conversaciones valiosas por tener antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es donde las cosas empiezan a ser realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente empuja cuando habla de IA, este sistema **ofrece a los humanos un rol más creativo**.

Imagina un equipo de lingüistas y estrategas de contenido teniendo una sesión donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, consultar contexto cultural al que ningún modelo puede acceder. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al grafo de contexto. El sistema se encarga de la propagación.

O lleva un paso más: imagina sesiones de agente donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo así?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo que ya hacen excelente: tomar decisiones lingüísticas matizadas e informadas culturalmente. El sistema maneja las partes mecánicas (propagación, análisis de impacto, consistencia) mientras los humanos se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía con la equivalencia dinámica. El objetivo no es la exactitud lingüística en un sentido mecánico. Se trata de crear la misma relación sentida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente buenos y que los modelos siguen luchando por manejar. El trabajo del sistema es asegurarse de que esos hallazgos humanos se capturen, estructuren y sean reutilizables.

## ¿Qué sigue?

En una publicación posterior, nos adentraremos más en lo técnico y hablaremos sobre el papel que jugarán los entornos aislados al habilitar experiencias aún no vistas en este espacio, y por qué estamos invirtiendo fuertemente en APIs. Existe toda una dimensión relacionada con el staging, la previsualización y la prueba de cambios lingüísticos antes de que se pongan en producción que nos emocionamos explorar.

Si algo de esto resuena contigo, ya seas un lingüista frustrado con las herramientas actuales, un desarrollador que ha luchado con los flujos de trabajo de localización o simplemente alguien que piensa profundamente sobre la intersección entre el idioma y la tecnología, nos encantaría oírte.