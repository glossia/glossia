%{
  title: "El grafo de contexto: codificando décadas de teoría lingüística para la era agéntica",
  summary:
    "Los modelos de lenguaje son potentes, pero necesitan el contexto adecuado para producir gran contenido. Estamos diseñando un grafo dirigido y versionado para capturar el conocimiento lingüístico y compartirlo con agentes, y creemos que esto es lo que hará que Glossia destaque.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
He estado pensando mucho en qué hace la diferencia entre el contenido que suena generado por máquina y el contenido que parece escrito por alguien que entiende la audiencia, la marca y los matices culturales detrás de cada palabra. La respuesta sigue volviendo a lo mismo: **contexto**.

Los modelos de lenguaje están mejorando en idiomas, y apostamos a que esa trayectoria continúe. Aún no están del todo ahí, pero el ritmo de mejora es difícil de ignorar. Lo que aún falta, sin embargo, es el sistema que se sitúa entre el modelo y el contenido. La cosa que le dice al modelo *quién* eres, *cómo* hablas, *qué* importa en esta frase específica, y *por qué* esa frase existe en primer lugar. Ese es el problema en el que estamos trabajando en Glossia, y creo que es el más interesante del sector actualmente.

## Tres elementos, dos que controlamos

Cuando miro lo que se necesita para habilitar un enfoque genuinamente nuevo hacia el contenido monolingüe y multilingüe, veo tres elementos:

1. **Modelos que funcionan bien con idiomas.** Aún no están del todo ahí, pero están mejorando rápido y apostamos por esa tendencia. No necesitamos construir un modelo base. Necesitamos estar listos para usarlos bien cuando lo consigan.
2. **Un sistema para modelar y compartir el contexto que necesitan los agentes.** Esta es la pieza que se sitúa entre el modelo y el contenido. La capa que captura tu voz, tu terminología, tu tono, las expectativas de tu audiencia y sirve todo eso al agente de forma estructurada.
3. **El contexto que proviene de los usuarios.** Los seres humanos aportan juicio, conciencia cultural y dirección creativa. Ningún sistema puede reemplazar eso completamente. Pero un sistema puede hacerlo fácil de capturar y reutilizar.

De estos tres, hay dos que controlamos: el sistema en sí y cómo guiamos a los usuarios para que contribuyan contexto y nos ayuden a mejorar el sistema. Creemos que acertar en ambos es lo que hará que Glossia destaque en un espacio que se está llenando rápidamente de soluciones de tipo \\"solo conecta un LLM\\". El sistema es donde necesitamos codificar décadas de teoría lingüística en las primitivas que están emergiendo en el mundo de los agentes. Y la experiencia de usuario que lo rodea es cómo nos aseguramos de que el contexto adecuado se capture, refine y devuelva al bucle.

Eugene Nida, uno de los fundadores de los estudios modernos de traducción, sostuvo que una buena traducción no se trata de una correspondencia palabra por palabra. Su concepto de [equivalencia dinámica](https://en.wikipedia.org/wiki/Dynamic_equivalence) dice que la relación entre la audiencia objetivo y el mensaje traducido debería sentirse igual que la relación entre la audiencia original y la fuente. Esa es una idea hermosa, pero requiere una comprensión contextual profunda: quién está leyendo, qué marco cultural traen, qué tono perseguía el original. Estas son exactamente los tipos de cosas que necesitan vivir en algún lugar donde un modelo pueda acceder a ellas.

## Lo que necesitamos capturar, y cómo

Uno de los primeros temas que hemos estado explorando es qué información debe capturarse y cómo estructurarla para que los agentes puedan utilizarla de verdad. Cuanto más pensábamos en ello, más nos dimos cuenta de que no era un archivo de configuración plano ni una página de configuración. Necesitaba ser un grafo. Específicamente, un **[grafo dirigido acíclico](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

¿Por qué un DAG? Porque **el contexto no es plano**. Tu voz de marca influye en tu terminología. Tu terminología moldea cómo escribes sobre funciones específicas. Las expectativas de tu audiencia informan el nivel de formalidad, lo que a su vez afecta la elección de palabras. Estas relaciones tienen dirección y jerarquía, y no vuelven sobre sí mismas.

Aquí hay antecedentes previos. Los grafos de conocimiento se han utilizado durante años en sistemas de IA para representar relaciones estructuradas entre conceptos. Más recentemente [grafos de contexto](https://grokipedia.com/page/context-graph) han extendido esa idea añadiendo capas de contexto dinámicas, exactamente lo que los agentes necesitan para tomar decisiones informadas. Y en el mundo de múltiples agentes [los DAGs se han convertido en un patrón fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependencias de tareas y flujo de información.

Pero aquí está la parte que me apasiona: **cada nodo de este grafo necesita ser versionado**. Cuando cambias tu voz de marca, no deberías perder acceso a la versión anterior. Cuando actualizas una entrada de terminología, el sistema debe saber qué contenido se produjo bajo la definición anterior y qué piezas podrían necesitar ser revisadas. Esto es lo que nos permite optimizar el flujo de trabajo agéntico para que solo se active para las piezas que realmente están afectadas por un cambio, en lugar de reprocesar todo.

## Bidireccional por diseño

Creemos que la relación entre los nodos de contexto y el contenido debe ser direccional, y debe funcionar en ambas direcciones.

Mirándolo desde un lado: necesitas saber cómo el contenido está conectado al contexto. Cuando un elemento de contexto cambia (por ejemplo, tu voz de marca cambia para ser más informal), ¿cuáles posts de blog, descripciones de productos o artículos de ayuda fueron escritos bajo la versión anterior? Aquellos son los que deben ser repasados o retraducidos. Este es el **dirección hacia adelante, desde el contexto hacia el contenido**.

Desde el otro lado: cuando un lingüista revisa un elemento de contenido y se pregunta por qué se tomó una decisión particular, debe poder rastrearlo de vuelta al contexto que orientó dicha decisión. ¿Qué definición de voz estaba activa? ¿Qué regla de terminología se aplicó? Esto **trazabilidad hacia atrás** es lo que permite a los humanos entender qué hicieron los agentes e iterar sobre ello con confianza.

NASA llama esto [rastreo bidireccional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacidad de seguir una asociación entre entidades en cualquier dirección. Es un principio de la ingeniería de sistemas, y resulta ser exactamente lo que necesitas cuando intentas crear un bucle de retroalimentación entre el contexto lingüístico y el contenido generado.

Esta cualidad bidireccional es lo que hace **refinamiento progresivo** es posible. Un lingüista puede revisar una pieza de contenido, ver el contexto que lo moldeó, decidir que la definición de voz necesita ajuste y crear ese ajuste. El sistema entonces sabe exactamente qué otro contenido se ve afectado por el cambio. Es un bucle cerrado y profundamente humano.

## Más allá de un único repositorio

Hay otra dimensión en este gráfico que encuentro particularmente interesante. **No puede alojarse en un único repositorio.** El grafo de contexto debe ser compartible entre proyectos y, potencialmente, entre organizaciones.

Piénsalo: una empresa tiene una voz de marca. Esa voz se aplica a cada producto, cada sitio web, cada artículo de soporte. No reside en un único repositorio. Es una preocupación transversal. Podrías definir tu voz central a nivel de organización y luego aplicar sobrescrituras a nivel de proyecto para un producto o audiencia específica. Esto es **herencia de alcance**, el mismo patrón al que estamos acostumbrados en programación, pero aplicado al contexto lingüístico.

Y este contexto necesita ser versionado correctamente. No puedes simplemente cambiar la definición de voz y borrar la versión anterior. Hay mucho que aprender de cómo [, Git gestiona el control de versiones](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) a través del almacenamiento direccionable por contenido y DAGs. El modelo de Git de commits, ramas y diffs se trata fundamentalmente de rastrear cómo las cosas cambian con el tiempo mientras se preserva el acceso a cada estado anterior. Eso es exactamente lo que necesitamos para el contexto lingüístico.

De hecho, creemos que un cambio de voz debería ocurrir a través de algo al que llamamos una *solicitud de cambio de voz*. Como una solicitud de extracción crea un espacio para debatir cambios de código, una solicitud de cambio de voz crea un espacio para discutir cambios lingüísticos. ¿Por qué estamos pasando a un tono más conversacional? ¿Cuál será el impacto? ¿Qué contenido se verá afectado? Estas son conversaciones que vale la pena tener antes de que el cambio se propague.

## Donde los humanos se vuelven más creativos, no menos relevantes

Y es aquí cuando las cosas comienzan a volverse realmente interesantes. En lugar de eliminar a los humanos, lo cual es la narrativa que mucha gente empuja cuando habla de la IA, este sistema **da a los humanos un papel más creativo**,

Imagina un equipo de lingüistas y estrategas de contenido en una sesion de traduccion donde discuten ideas sobre la dirección lingüística de la marca. Podrían explorar conceptos, debatir cambios de tono, referirse a un contexto cultural al que ningún modelo tiene acceso. Luego, en lugar de actualizar manualmente cientos de archivos, capturan sus decisiones como ajustes al context graph. El sistema se encarga de la propagación.

O llevémonos un paso más allá: imagina sesiones agénticas donde un lingüista trabaja con un asistente de IA para explorar ideas lingüísticas. "¿Qué pasaría si hiciéramos los mensajes de error más empáticos?" El agente simula el impacto, muestra cómo cambiaría el contexto actual, previsualiza cómo podría verse el contenido actualizado. El lingüista refina, ajusta y, cuando está satisfecho, envía una solicitud de cambio de contexto. ¿No sería algo increíble?

**Esto no se trata de sustituir al lingüista.** Se trata de darles mejores herramientas para aprovechar su mayor fortaleza: tomar decisiones matizadas y culturalmente informadas sobre el idioma. El sistema maneja las partes mecánicas (propagación, análisis de impacto, consistencia) mientras las personas se centran en las partes creativas (voz, tono, resonancia cultural).

Sigo volviendo a lo que Nida pretendía con la equivalencia dinámica. El objetivo no es la precisión lingüística en un sentido mecánico. Se trata de crear la misma relación perceptida entre el lector y el contenido, independientemente del idioma. Eso requiere gusto, criterio y conciencia cultural. Es algo en lo que los humanos son sorprendentemente expertos, algo con lo que los modelos aún luchan. La función del sistema es asegurar que esas apreciaciones humanas sean capturadas, estructuradas y reutilizables.

## ¿Qué sigue?

En una publicación posterior, profundizaremos más en los aspectos técnicos y hablaremos sobre el papel que los entornos aislados jugarán para habilitar experiencias que aún no se han visto en este espacio, y por qué estamos invirtiendo fuertemente en las APIs. Existe toda una dimensión en torno a la fase de pruebas, previsualización y validación de cambios lingüísticos antes de su lanzamiento que queremos explorar.

Si alguna de estas ideas resuena con usted, ya sea un lingüista frustrado con las herramientas actuales, un desarrollador que haya luchado con los flujos de trabajo de localización, o simplemente alguien que piense profundamente sobre cómo se cruzan el lenguaje y la tecnología, nos encantaría escuchar de usted.