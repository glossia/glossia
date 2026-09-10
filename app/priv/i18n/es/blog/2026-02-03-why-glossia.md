%{
  title:
    "La localización se había estancado en el pasado. Construimos Glossia para llevarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen la CI y te confinan en ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo de localización basado en agentes.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, ya sabes el proceso. Eliges una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven y en algún punto del medio las cosas se rompen.

Esa sobrecarga, el ciclo de ida y vuelta constante de contenido entre tu repositorio, es el impuesto que cada equipo paga por usar las herramientas de localización actuales. Parece insignificante hasta que eres tú quien depura por qué una PR de traducción rompió la compilación del sitio a las 6 PM del viernes.

## Un diseño heredado de antes de Internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos que preceden al flujo de trabajo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar de cero, o pagar por una exportación que nunca funciona como cabría esperar.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el horario de alguien más.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu flujo de CI. No saben sobre tus linters, tu paso de construcción, tu verificador de enlaces o tu esquema frontmatter. Empujan contenido traducido de vuelta a tu repositorio y esperan lo mejor. Cuando falla, y falla, alguien del equipo tiene que detener lo que está haciendo para solucionar problemas de formato, sintaxis rota o marcado no válido que introdujo la herramienta de traducción.

Los LLMs y las experiencias agénticas nos presentan nuevas oportunidades para repensar por completo estos flujos de trabajo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y reintenta hasta que la salida sea válida. Ese tipo de bucle de retroalimentación estrecho cambia todo.

Pero solo funciona si el contenido se mantiene en su lugar original: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones vuelven bajo el cronograma de otra persona y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora lleva horas o días. El contexto que la hacía útil ha desaparecido. Pierdes el bucle, y con él, toda la ventaja que supuestamente ofrecían los flujos de trabajo agénticos.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo cual dio claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las cuales las herramientas existentes terminaron así fue esencial.

Juntos, llegamos repetidamente a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de programación y sin pipelines de CI. El modelo completo asumía que la traducción era algo que ocurría fuera del flujo de desarrollo y se devolvía hacia adentro. Eso tenía sentido hace diez años. Ya no tiene sentido.

Comenzamos a preguntarnos: **¿y qué pasaría si los agentes de localización pudieran trabajar de la misma manera que los agentes de programación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en flujos de trabajo agénticos con Claude. El patrón de otorgar a un agente acceso a herramientas, permitirle razonar a través de una tarea, validar su propia salida e iterar cuando algo va mal, se alinea notablemente bien con la localización. Un agente de traducción que pueda leer sus archivos fuente, entender el contexto del proyecto, generar traducciones, ejecutar su linter y solucionar problemas antes de abrir una solicitud de extracción. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo a la industria del software.

Construimos Glossia porque queremos que más software esté localizado, no menos.

Los procesos complejos y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si su flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gerente de proyectos para coordinar las entregas, la mayoría de los equipos simplemente publicará en inglés y lo dejará ahí.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces secundarias

En esencia, Glossia es un agente. Empezamos con la terminal como su interfaz principal, porque es allí donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus validaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Lo hablamos con frecuencia internamente. Las personas que más valoran la precisión de la traducción, el tono y los matices culturales suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Aportan el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente se encarga de todo lo demás: hacer commits, validar, abrir la solicitud de extracción.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto con detenimiento antes que precipitarnos en una interfaz que pierda el objetivo. Pero la dirección está clara: Glossia debe dar la bienvenida a todos los que se preocupan por hacer que el software hable todos los idiomas.

## Mantente al tanto

Glossia aún está en sus inicios, y lo estamos construyendo de forma abierta. Si algo de esto resuena con tu forma de pensar sobre la localización, mantente atento al proyecto. Compartiremos más a medida que avancemos.