%{
  title: "Construyendo una empresa centrada en la IA para desafiar a una industria que no puede reinventarse a sí misma",
  summary: "Las empresas de localización establecidas tienen el capital pero no la libertad para innovar. Estamos diseñando Glossia desde cero en torno a la IA y los agentes, no solo en el producto, sino en cómo gestionamos todo el negocio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs y agentes están transformando todo. No solo lo que el software puede hacer, sino cómo se construyen las empresas para crear ese software. En [Glossia](https://glossia.ai), vemos esto como una oportunidad de una generación para repensar cómo el contenido llega a todos los idiomas. Pero también sabemos que tener una buena idea de producto no es suficiente. Necesitas una organización que pueda moverse lo suficientemente rápido como para que cuente.

La segunda parte es a la que se refiere esta publicación.

## El dilema del innovador, en tiempo real

La industria de la localización es grande y muy financiada. Empresas como Smartling, Phrase, Crowdin y Lokalise llevan años desarrollando herramientas y servicios. Tienen clientes, ingresos, flujos de trabajo establecidos y equipos que saben cómo vender y dar soporte a sus productos.

¿Entonces por qué un equipo de dos personas incluso lo intentaría?

Por algo que Clayton Christensen describió en [El dilema del innovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): las empresas establecidas luchan por adoptar la innovación disruptiva, no porque carezcan de recursos, sino porque sus modelos de negocio existentes, las expectativas de los clientes y las estructuras organizativas les impiden hacerlo.

Estas empresas construyeron sus productos alrededor de las memorias de traducción, la precificación por palabra y los flujos de trabajo de los traductores humanos. Sus clientes han construido modelos mentales y procesos en torno a esos componentes básicos. Cambiar los fundamentos significa romper promesas a clientes existentes, recapacitar equipos y replantear los modelos de ingresos. Incluso con las mejores intenciones y el capital para invertir, la inercia organizacional es enorme.

Necesitan capacidad de innovación y compromiso de su fuerza laboral para abrazar nuevas ideas. Pero incluso más difícil que eso, necesitan que sus clientes existentes se sumen al viaje. Y esos clientes están comprometidos con el modelo antiguo.

Esta es la oportunidad que vemos. No a pesar de tener menos recursos, sino gracias a ello. No tenemos un legado que proteger, ni flujos de trabajo que preservar, ni clientes que migrar. Podemos diseñar todo desde cero.

> \[\!NOTE\]
> El dilema del innovador no se trata de tecnología. Se trata de incentivos. Las empresas establecidas optimizan para lo que sus clientes actuales quieren, lo que hace casi imposible perseguir algo fundamentalmente diferente.

## IA en el centro, no en los bordes

La mayoría de las empresas adoptan IA atándola a los procesos existentes. Un chatbot aquí, un motor de sugerencias allí. Vamos en la dirección opuesta: diseñamos toda la empresa para que sea centrada en la IA desde el primer día.

Esto significa que la IA no es una característica del producto. Moldea cómo construimos, vendemos, damos soporte y operamos. Cada decisión que tomamos comienza con una pregunta: ¿puede un agente hacer esto?

El producto en sí mismo es un agente que vive en tu terminal, lee tus archivos de origen, genera traducciones, ejecuta tus comprobaciones CI y se itera hasta que el resultado pasa. Eso es lo que la gente ve. Pero detrás de ello, esa misma filosofía impulsa el negocio.

## Dos personas, cero sobrecarga organizacional

Estamos manteniendo deliberadamente el equipo lo más pequeño posible. Actualmente son solo dos personas. Nuestro objetivo es mantenernos a dos o tres personas tanto como podamos.

No se trata de ahorrar dinero (aunque ayuda). Se trata de eliminar una categoría completa de trabajo que no genera valor para los usuarios.

Cuanto más humanos añadas, más coordinación necesitas. Construyes sistemas de confianza, modelos de permisos, cadenas de aprobación. Gestionas conflictos, alineas prioridades, agendas reuniones. Todo eso es energía creativa que se destina a mantener una organización humana en lugar de construir un producto.

Con dos personas, saltamos todo eso. Nos confiamos mutuamente. Tenemos acceso a todo. No hay sobrecarga, no hay política, no hay proceso por el mero proceso.

La forma en que hacemos que esto funcione a gran escala es delegando todo lo demás en agentes.

## Discord, un agente de IA y una línea de comandos

Aquí hay algo que puede sonar inusual: nuestra interfaz de negocio principal es un servidor de [Discord](https://discord.com).

Tenemos un agente de IA conectado a él, impulsado por [OpenAI](https://openai.com), con acceso a todas las herramientas que necesitamos para gestionar el negocio. En su lugar, hablamos al agente. El texto y la voz son la unidad de interacción.

A través del agente, cualquiera de nosotros puede:

- Consultar análisis de marketing y productos
- Inspeccionar servidores de producción
- Ejecutar investigaciones de mercado
- Recopilar retroalimentación de los clientes
- Realizar análisis competitivo mediante navegación web
- Redactar contenido, revisar textos y publicar

Ninguno de nosotros depende del otro para hacer ninguna de estas cosas. El agente tiene acceso a nuestras APIs, bases de datos y herramientas de monitorización. Puede navegar por la web, leer documentación y sintetizar información. Es un servidor de Discord, una instancia de OpenAI y una clave de LLM. Eso es el sistema operativo de la empresa.

> \[\!TIP\]
> Si estás construyendo un equipo pequeño y quieres reducir la sobrecarga de coordinación, considera hacer que el texto y la voz sean tu interfaz principal para las operaciones del negocio. Un agente compartido en un canal de chat puede reemplazar docenas de paneles de control y eliminar la necesidad de la mayoría de las herramientas internas.

## Elección deliberada de tecnologías

Somos muy intencionales sobre nuestro stack porque afecta directamente lo rápido que podemos avanzar y lo barato que podemos operar.

**Para el agente (CLI):** Optamos por Go. Compila en binarios únicos y portátiles en todas las plataformas sin dependencias de tiempo de ejecución para el usuario.

**Para el servidor:** Optamos por [Elixir](https://elixir-lang.org) y el runtime de [Erlang](https://www.erlang.org). La naturaleza funcional de Elixir lo hace una gran opción para cargas de trabajo de agentes. La máquina virtual de Erlang ha sido probada para concurrencia y tolerancia a fallos. Y aquí está el bono: un agente de IA puede introspeccionar el sistema Erlang en ejecución para entender qué está pasando, recopilar conocimientos y hasta corregir problemas en producción.

**Para la infraestructura:** Todo corre en un único VPS. No solo el servidor de producción de Glossia, sino todos los servicios periféricos también: [PostgreSQL](https://www.postgresql.org/) para la base de datos, [Plausible](https://plausible.io) para análisis amigos a la privacidad, [Grafana](https://grafana.com) para telemetría y observabilidad. Todo se despliega desde definiciones de infraestructura controladas por versiones que describen qué va a dónde.

Esto mantiene los costos extremadamente bajos. No dependemos de servicios en la nube de terceros, bases de datos gestionadas o proveedores de plataforma como servicio. Tenemos pocas dependencias externas, pero solo para cosas que tomarían mucho tiempo replicar y donde el costo tiene sentido.

Cuando llegue el momento de escalar entre servidores, evolucionaremos el modelo. Pero creemos que podemos llegar muy lejos con esta configuración. Y avanzar rápido importa más que crecer grande ahora mismo.

> \[\!IMPORTANT\]
> Somos muy deliberados al omitir la complejidad técnica a la que los ingenieros suelen recurrir pronto. Kubernetes, microservicios, despliegues multi-región. Nada de eso es necesario en esta etapa, y todo eso nos volvería más lentos.

## Lo que esto desbloquea

Operar la empresa de esta manera no es solo una estrategia de eficiencia. Cambia lo que podemos ofrecer y lo rápido que podemos aprender.

**Más barato para los usuarios.** La industria de la localización ha hecho sus herramientas inaccesibles mediante precios complejos, tarifas por palabra y ciclos de ventas empresariales. Si tu flujo de trabajo de traducción requiere compras, negociaciones de precios y un jefe de proyecto, la mayoría de los equipos pequeños solo lo lanzarán en inglés. Al mantener nuestros costos operativos cercanos a cero, podemos ofrecer algo que sea realmente accesible.

**Innovación más rápida.** Queremos explorar muchas ideas. Nuevas interfaces para el agente, mejores bucles de retroalimentación, nuevas formas de integrar lingüistas en el flujo de trabajo. Una empresa tradicional necesitaría contratar personal, alinear equipos y agendar revisiones de la hoja de ruta. Solo probamos cosas. La distancia entre una idea y un experimento desplegado se mide en horas, no en trimestres.

## El desafío de cómo trabajamos, no solo lo que construimos

No estamos emocionalmente apegados a las antiguas formas de hacer las cosas. Estamos cuestionando activamente qué significa la revisión de código cuando un agente escribe la mayor parte del código. Cómo funciona la colaboración cuando solo hay dos personas. Cómo se soluciona un error cuando el agente puede inspeccionar el sistema en ejecución.

Cometemos errores. Seguiremos cometiendo errores. Pero al mantenernos abiertos respecto a cómo diseñamos y gestionamos el negocio, seguimos descubriendo ideas que influyen en el producto. La forma en que operamos no está separada de lo que construimos. Son lo mismo.

[McKinsey describió recientemente](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) lo que denominan la "organización agente", un nuevo modelo de operaciones donde los agentes de IA se convierten en participantes de primera clase en cómo funciona una empresa. No lo concebimos como un modelo. Es simplemente cómo trabajamos.

## La apuesta

Apostamos a que un equipo de dos personas con las herramientas adecuadas, la mentalidad correcta y sin lastre organizativo puede superar a empresas con cientos de empleados y millones en financiación. No en todos los frentes, sino en el que importa: entregar una experiencia de localización fundamentalmente mejor.

La industria no puede reinventarse. Nosotros sí.