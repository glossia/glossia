%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agencial",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para producir gran contenido. Estamos diseñando un grafo versionado y dirigido para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia se destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en lo que marca la diferencia entre el contenido que suena generado por una máquina y el contenido que parece escrito por alguien que entiende la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta siempre vuelve al mismo punto: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos a que esa trayectoria continúe. Aún no están totalmente allí, pero el ritmo de mejora es difícil de ignorar. Lo que falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. Lo que indica al modelo *quién* eres, *cómo* hablas, *qué* importa en esta oración en particular, y *por qué* esa oración existe en primer lugar. Eso es el problema con el que trabajamos en Glossia, y creo que es el más interesante en el espacio actualmente.

## Tres elementos, dos que controlamos

Cuando miro qué se necesita para habilitar un enfoque genuinamente nuevo para contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que son buenos en idiomas.** Aún no están del todo ahí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo de base. Necesitamos estar listos para usarlos bien cuando lleguen.
2. **Un sistema para modelar y compartir el contexto que los agentes necesitan.** Esto es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia, y sirve todo eso al agente de una manera estructurada.
3. **El contexto que proviene de los usuarios.** Los humanos aportan criterio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazarlo completamente. Pero un sistema puede hacerlo fácil de capturar y reutilizar.

De estas tres, hay dos que controlamos: el sistema en sí y cómo guiamos a los usuarios para que contribuyan contexto y nos ayuden a mejorar el sistema. Creemos que hacer ambas cosas bien es lo que hará que Glossia destaque en un espacio que se llena rápidamente de soluciones de "solo integrar un LLM". El sistema es donde necesitamos codificar décadas de teoría lingüística en los primitivos que están emergiendo en el mundo de los agentes. Y la experiencia de usuario que lo rodea es cómo aseguramos que el contexto correcto realmente se capture, se refine y se realimente de nuevo al bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, argumentó que la buena traducción no se trata de correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debe percibirse igual que la relación entre la audiencia original y la fuente. Es una idea hermosa, pero requiere una comprensión contextual profunda: quién lee, qué marco cultural traen, qué tono buscaba el original. Estas son exactamente las clases de cosas que deben residir en algún lugar al que un modelo pueda acceder a ellas.

## Lo que necesitamos capturar y cómo

Una de las primeras cosas que hemos estado explorando es qué información necesita ser capturada y cómo estructurarla para que los agentes puedan usarla realmente. Cuanto más pensamos, más nos dimos cuenta de que esto no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**,

¿Por qué un DAG? Porque **el contexto no es plano**La voz de su marca influye en su terminología. Su terminología moldea cómo escribe sobre características específicas. Las expectativas de su audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no forman bucles entre sí.

Aquí hay antecedentes. Los gráficos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recientemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea agregando capas de contexto dinámicas, exactamente el tipo de cosa que los agentes necesitan para tomar decisiones informadas. Y en el mundo de los agentes múltiples, [Los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me entusiasma: **cada nodo en este gráfico necesita ser versionado**. Cuando cambias tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debe saber qué contenido se produjo bajo la definición anterior y qué elementos podrían necesitar ser revisados. Esto es lo que nos permite optimizar el flujo de trabajo de los agentes para que solo se active para las piezas que realmente se ven afectadas por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional y funcionar en ambas direcciones.

Desde una perspectiva: necesitas saber cómo se conecta el contenido al contexto. Cuando cambia una pieza de contexto (por ejemplo, tu voz de marca se vuelve más informal), ¿qué publicaciones de blog, descripciones de productos o artículos de ayuda se escribieron bajo la versión anterior? Son esos los que deben ser revisados o retraducidos. Esto es la **dirección hacia adelante, desde el contexto hacia el contenido**.

Desde el otro lado: cuando un traductor revisa un fragmento de contenido y se pregunta por qué se tomó una decisión concreta, debería poder trazarlo de vuelta al contexto que la guió. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esta **trazabilidad hacia atrás** es lo que permite a las personas entender lo que hicieron los agentes e iterar sobre ello con confianza.

NASA llama a esto [trazabilidad bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en una u otra dirección. Es un principio de la ingeniería de sistemas y resulta ser exactamente lo que necesitas cuando intentas crear un ciclo de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta calidad bidireccional es lo que hace **refinamiento progresivo** posible. Un lingüista puede revisar un fragmento de contenido, ver el contexto que lo dio forma, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un ciclo cerrado y es profundamente humano.

## Más allá de un solo repositorio

Hay otra dimensión en este grafo que me resulta particularmente interesante. **No puede estar contenido en un solo repositorio.** El gráfico de contexto debe ser compartible entre proyectos, y potencialmente entre organizaciones.

Piénselo: una empresa tiene una voz de marca. Esa voz se aplica en cada producto, cada sitio web, cada artículo de soporte. No vive en un solo repositorio. Es una preocupación transversal. Podrías definir su voz central a nivel de organización, luego aplicar sobrescrituras a nivel de proyecto para un producto o audiencia específica. Esto es **herencia de alcance**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita ser versionado correctamente. No puedes cambiar solo la definición de voz y eliminar la versión anterior. Hay mucho que aprender de cómo [Git gestiona el versionamiento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través del almacenamiento direccionable por contenido y DAGs. El modelo de Git de comits, ramas y diferenças se trata fundamentalmente de rastrear cómo cambian las cosas con el tiempo mientras se preserva el acceso a cada estado previo. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, pensamos que un cambio de voz debe ocurrir a través de algo al que llamamos un *solicitud de cambio de voz.*. Al igual que una pull request crea un espacio para debatir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos cambiando a un tono más conversacional? ¿Cuál será el impacto? ¿Qué contenido se verá afectado? Estas son conversaciones valiosas de tener antes de que el cambio se propague.

## Donde los humanos se vuelvan más creativos, no menos relevantes

Y es aquí donde las cosas empiezan a volverse realmente interesantes. En lugar de eliminar a los humanos, que es la narrativa que mucha gente impulsa cuando habla de IA, este sistema **otorga a los humanos un papel más creativo.**.

Imagina un equipo de lingüistas y estrategas de contenido en una sesión donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, referenciar contexto cultural al que ningún modelo tiene acceso. Y luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al grafo de contexto. El sistema se encarga de la propagación.

O avancemos un passo más: imaginen sesiones ágenticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería increíble?

**Esto no se trata de reemplazar al lingüista.** Se trata de darles mejores herramientas para hacer lo en lo que ya son expertos: tomar decisiones matizadas y culturalmente informadas sobre el idioma. El sistema gestiona las partes mecánicas (propagación, análisis de impacto, coherencia) mientras las personas se centran en las partes creativas (voz, tono, resonancia cultural).

Vuelvo una y otra vez a lo que pretendía Nida con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación percibida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, juicio y conciencia cultural. Cosas en las que los humanos son notablemente hábiles, y con las que los modelos aún luchan. El objetivo del sistema es asegurarse de que esos conocimientos humanos sean capturados, estructurados y reutilizables.

## ¿Qué sigue?

En una publicación posterior, abordaremos aspectos más técnicos y hablaremos sobre el papel que jugarán los entornos aislados para habilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en las APIs. Existe toda una dimensión en torno a la fase de pruebas, la previsualización y la prueba de cambios lingüísticos antes de que se pongan en producción, sobre lo cual estamos emocionados de profundizar.

Si esto resuena con usted, ya sea que sea un lingüista frustrado con las herramientas actuales, un desarrollador que haya luchado con los flujos de trabajo de localización, o simplemente alguien que piense en profundidad sobre cómo se intersectan el idioma y la tecnología, nos encantaría escuchar de usted.