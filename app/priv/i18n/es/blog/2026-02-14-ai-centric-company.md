%{
  title: "Crear una empresa centrada en la IA para desafiar a un sector que no puede reinventarse",
  summary: "Las empresas de localización consolidadas tienen el capital, pero no la libertad para innovar. Estamos diseñando Glossia desde cero en torno a la IA y los agentes, no solo en el producto, sino también en la forma en que gestionamos todo el negocio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Los modelos de lenguaje y los agentes lo están transformando todo. No solo lo que el software puede hacer, sino también cómo se crean las empresas que desarrollan ese software. En [Glossia](https://glossia.ai), vemos una oportunidad única en una generación para replantear cómo llega el contenido a todos los idiomas. Pero también sabemos que no basta con tener una buena idea de producto. Se necesita una organización capaz de avanzar con la rapidez necesaria para generar un impacto real.

Esta publicación trata sobre esa segunda parte.

## El dilema del innovador en tiempo real

La industria de la localización es grande y cuenta con una financiación considerable. Empresas como Smartling, Phrase, Crowdin y Lokalise llevan años desarrollando herramientas y servicios. Tienen clientes, ingresos, flujos de trabajo consolidados y equipos que saben cómo vender y prestar asistencia para sus productos.

Entonces, ¿por qué lo intentaría siquiera un equipo de dos personas?

Por algo que Clayton Christensen describió en [El dilema del innovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): las empresas consolidadas tienen dificultades para adoptar innovaciones disruptivas, no porque carezcan de recursos, sino porque sus modelos de negocio, las expectativas de sus clientes y sus estructuras organizativas se lo impiden.

Estas empresas construyeron sus productos en torno a memorias de traducción, precios por palabra y flujos de trabajo para traductores humanos. Sus clientes han desarrollado modelos mentales y procesos basados en esos pilares. Cambiar los cimientos implica incumplir compromisos con clientes existentes, volver a formar a los equipos y replantear los modelos de ingresos. Incluso con las mejores intenciones y el capital necesario para invertir, la inercia organizativa es enorme.

Necesitan capacidad de innovación y el compromiso de su personal para adoptar nuevas ideas. Pero hay algo aún más difícil: necesitan que sus clientes actuales se sumen al cambio. Y esos clientes han invertido en el modelo anterior.

Esta es la oportunidad que vemos. No a pesar de tener menos recursos, sino precisamente por ello. No tenemos un legado que proteger, flujos de trabajo que conservar ni clientes que migrar. Podemos diseñarlo todo desde cero.

> [!NOTE]
> El dilema del innovador no trata sobre tecnología. Trata sobre incentivos. Las empresas consolidadas optimizan sus productos para satisfacer lo que quieren sus clientes actuales, lo que hace casi imposible perseguir algo radicalmente distinto.

## La inteligencia artificial en el centro, no en los márgenes

La mayoría de las empresas adopta la inteligencia artificial añadiéndola a procesos existentes. Un chatbot aquí, un motor de sugerencias allá. Nosotros avanzamos en la dirección opuesta: diseñamos toda la empresa en torno a la inteligencia artificial desde el primer día.

Esto significa que la inteligencia artificial no es una función del producto. Define cómo desarrollamos, vendemos, prestamos asistencia y operamos. Cada decisión que tomamos comienza con una pregunta: ¿puede hacer esto un agente?

El propio producto es un agente que reside en su terminal, lee sus archivos fuente, genera traducciones, ejecuta las comprobaciones de integración continua e itera hasta que el resultado las supera. Esa es la parte que ven las personas. Pero, tras ella, la misma filosofía dirige el negocio.

## Dos personas, ninguna carga organizativa

Mantenemos el equipo tan pequeño como sea posible de forma deliberada. Ahora mismo somos solo dos personas. Nuestro objetivo es seguir siendo dos o tres durante el mayor tiempo posible.

No se trata de ahorrar dinero, aunque ayuda. Se trata de eliminar toda una categoría de trabajo que no aporta valor a los usuarios.

Cuantas más personas se incorporan, más coordinación se necesita. Hay que crear sistemas de confianza, modelos de permisos y cadenas de aprobación. Hay que gestionar conflictos, alinear prioridades y programar reuniones. Todo ello consume energía creativa para mantener una organización humana en lugar de desarrollar un producto.

Con dos personas, evitamos todo eso. Confiamos plenamente el uno en el otro. Ambos tenemos acceso a todo. No hay cargas innecesarias, política interna ni procesos por el mero hecho de tenerlos.

Para que esto funcione a escala, delegamos todo lo demás en agentes.

## Discord, un agente de inteligencia artificial y una única línea de comandos

Esto puede sonar inusual: nuestra principal interfaz empresarial es un servidor de [Discord](https://discord.com).

Tenemos un agente de inteligencia artificial conectado al servidor, basado en [OpenAI](https://openai.com), con acceso a todas las herramientas necesarias para gestionar el negocio. En lugar de alternar entre paneles web, plataformas de analítica y paneles de administración, hablamos con el agente. El texto y la voz son la unidad de interacción.

A través del agente, cualquiera de nosotros puede:

- Consultar datos de analítica de marketing y de producto
- Inspeccionar los servidores de producción
- Realizar estudios de mercado
- Recopilar comentarios de clientes
- Realizar análisis de la competencia mediante la navegación web
- Redactar contenido, revisar textos y publicar

Ninguno de nosotros depende del otro para hacer nada de esto. El agente tiene acceso a nuestras interfaces de programación de aplicaciones, bases de datos y herramientas de monitorización. Puede navegar por la web, leer documentación y sintetizar información. Es un servidor de Discord, una instancia de OpenAI y una clave de un modelo de lenguaje de gran tamaño. Ese es el sistema operativo de la empresa.

> [!TIP]
> Si está creando un equipo pequeño y quiere reducir la sobrecarga de coordinación, considere adoptar el texto y la voz como interfaz principal para las operaciones empresariales. Un agente compartido en un canal de chat puede sustituir decenas de paneles y eliminar la necesidad de la mayoría de las herramientas internas.

## Decisiones tecnológicas deliberadas

Elegimos nuestra arquitectura tecnológica de forma muy intencionada porque afecta directamente a la velocidad con la que podemos avanzar y al coste de nuestras operaciones.

**Para el agente (interfaz de línea de comandos):** Elegimos Go. Compila en un único archivo binario portátil para cada plataforma, sin dependencias de entorno de ejecución para el usuario.

**Para el servidor:** Elegimos [Elixir](https://elixir-lang.org) y el entorno de ejecución de [Erlang](https://www.erlang.org). La naturaleza funcional de Elixir lo hace muy adecuado para cargas de trabajo basadas en agentes. La máquina virtual de Erlang cuenta con una fiabilidad ampliamente demostrada para la concurrencia y la tolerancia a fallos. Además, ofrece otra ventaja: un agente de inteligencia artificial puede inspeccionar el sistema Erlang en ejecución para entender qué sucede, obtener información e incluso corregir problemas en producción.

**Para la infraestructura:** Todo se ejecuta en un único servidor privado virtual. No solo el servidor de producción de Glossia, sino también todos los servicios auxiliares: [PostgreSQL](https://www.postgresql.org/) para la base de datos, [Plausible](https://plausible.io) para una analítica respetuosa con la privacidad y [Grafana](https://grafana.com) para la telemetría y la observabilidad. Todo se despliega a partir de definiciones de infraestructura controladas por versiones que describen qué se instala y dónde.

Esto mantiene los costes extremadamente bajos. No dependemos de servicios externos en la nube, bases de datos gestionadas ni proveedores de plataformas como servicio. Tenemos algunas dependencias externas, pero solo para aquello que tardaríamos mucho tiempo en reproducir y cuyo coste está justificado.

Cuando llegue el momento de escalar a varios servidores, evolucionaremos el modelo. Sin embargo, creemos que podemos llegar muy lejos con esta configuración. Y ahora mismo, avanzar rápido importa más que crecer a gran escala.

> [!IMPORTANT]
> Evitamos de forma muy deliberada la complejidad técnica que los ingenieros suelen adoptar demasiado pronto. Kubernetes, microservicios y despliegues en varias regiones. Nada de esto es necesario en esta etapa y todo ello nos ralentizaría.

## Lo que esto permite

Gestionar la empresa de esta forma no es solo una estrategia de eficiencia. Cambia lo que podemos ofrecer y la velocidad con la que podemos aprender.

**Más económico para los usuarios.** El sector de la localización ha vuelto inaccesibles sus herramientas mediante precios complejos, tarifas por palabra y ciclos de venta empresariales. Si su flujo de trabajo de traducción requiere procesos de compra, negociaciones de precios y un gestor de proyecto, la mayoría de los equipos pequeños simplemente publicarán en inglés. Al mantener nuestros costes operativos cerca de cero, podemos ofrecer algo realmente accesible.

**Innovación más rápida.** Queremos explorar muchas ideas: nuevas interfaces para el agente, mejores ciclos de retroalimentación y nuevas formas de incorporar a lingüistas al flujo de trabajo. Una empresa tradicional tendría que ampliar su plantilla, coordinar equipos y programar revisiones de la hoja de ruta. Nosotros simplemente probamos cosas. La distancia entre una idea y un experimento desplegado se mide en horas, no en trimestres.

## Cuestionamos cómo trabajamos, no solo lo que creamos

No estamos apegados a las antiguas formas de hacer las cosas. Cuestionamos activamente qué significa revisar código cuando un agente escribe la mayor parte. Cómo funciona la colaboración cuando solo hay dos personas. Cómo se corrige un error cuando el agente puede inspeccionar el sistema en ejecución.

Cometemos errores. Y seguiremos cometiéndolos. Pero, al mantener una mentalidad abierta sobre cómo diseñamos y gestionamos la empresa, seguimos descubriendo ideas que influyen en el producto. Nuestra forma de operar no está separada de lo que creamos. Son lo mismo.

[McKinsey describió recientemente](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) lo que denomina «la organización agéntica», un nuevo modelo operativo en el que los agentes de inteligencia artificial se convierten en participantes de pleno derecho en el funcionamiento de una empresa. Nosotros no lo consideramos un modelo. Es simplemente nuestra forma de trabajar.

## La apuesta

Apostamos por que un equipo de dos personas, con las herramientas adecuadas, la mentalidad correcta y sin cargas organizativas, puede avanzar más rápido que empresas con cientos de empleados y millones de financiación. No en todos los frentes, sino en el que importa: ofrecer una experiencia de localización fundamentalmente mejor.

El sector no puede reinventarse. Nosotros sí.