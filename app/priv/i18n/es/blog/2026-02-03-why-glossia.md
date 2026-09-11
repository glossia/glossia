%{
  title:
    "La localización se había quedado estancada en el pasado. Creamos Glossia para avanzar con ella.",
  summary:
    "Las herramientas de localización tradicionales añaden sobrecarga, rompen la CI y te atan a los ecosistemas de proveedores. Estamos explorando qué aspecto puede tener un flujo de trabajo de localización con agentes.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has distribuido software en más de un idioma, sabes el procedimiento. Eleges una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven y, en algún punto intermedio, las cosas se rompen.

Ese sobrecargo, el constante viaje de ida y vuelta del contenido hacia y desde tu repositorio, es el coste que todo equipo paga por usar las herramientas de localización actuales. Suena menor hasta que eres tú el que depura por qué un PR de traducción rompió la construcción de tu sitio a las 6 PM del viernes.

## Un diseño heredado de antes de Internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos que preceden al flujo de trabajo moderno de desarrollo. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, residen dentro de su plataforma. Cambiar a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona del todo.

El resultado es una industria construida sobre fricción artificial. Tu contenido abandona tu repositorio, entra en una caja negra y regresa según el horario de otros.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No tienen conocimiento de tus linters, tu paso de compilación, tu verificador de enlaces, ni tu esquema de frontmatter. Devuelven el contenido traducido a tu repositorio y esperan lo mejor. Cuando falla, y lo hace, alguien del equipo tiene que detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias agénticas presentan nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y vuelve a intentarlo hasta que el resultado sea válido. Ese tipo de ciclo de retroalimentación estrecho cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan en el cronograma de otro, y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora toma horas o días. El contexto que la hacía útil ya ha desaparecido. Pierdes el ciclo y, con él, toda la ventaja que los flujos de trabajo agénticos debían ofrecerte.

## Observaciones que moldearon Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo que dio claridad a problemas difíciles de ver solo desde un lado. Entender los flujos de trabajo lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes terminaron así fue esencial.

Juntos, llegábamos constantemente a las mismas observaciones: las herramientas de localización estaban diseñadas para un mundo sin LLMs, sin agentes de codificación y sin pipelines de CI. El modelo entero asumía que la traducción era algo que ocurría fuera del flujo de trabajo de desarrollo y que se reintegraba dentro. Eso tenía sentido hace diez años. Ya no tiene sentido.

Comenzamos a preguntar: **¿qué pasaría si los agentes de localización pudieran trabajar de la misma manera que los agentes de codificación?**

Hemos estado prestando gran atención a cómo [Anthropic](https://anthropic.com) Piensa en flujos de trabajo autónomos con Claude. El patrón de dar acceso a herramientas a un agente, permitirle razonar a través de una tarea, validar su propia salida e iterar cuando algo falla encaja notablemente bien en la localización. Un agente de traducción que pueda leer tus archivos fuente, entender el contexto del proyecto, generar traducciones, ejecutar tu corrector y corregir problemas antes de abrir una solicitud de integración. Eso no es una fantasía. Es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Creamos Glossia porque queremos que más software se localice, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si su flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyecto para coordinar las entregas, la mayoría de los equipos simplemente lo lanzarán en inglés y se darán por terminados.

Glossia usa modelos a los que ya tienes acceso. Y valida la salida con sus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces después

En lo esencial, Glossia es un agente. Empezamos con la terminal como su interfaz principal porque es allí donde se resuelven primero los problemas más difíciles: leyendo tus archivos fuente, generando traducciones, ejecutando tus comprobaciones y iterando hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas que más se preocupan por la precisión de la traducción, el tono y el matiz cultural a menudo son lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Traen el criterio humano que ningún modelo puede reemplazar. Refinan lo que necesita perfeccionamiento. Y el agente se encarga del resto: hacer commits, validar y abrir la solicitud de extracción.

No tenemos todas las respuestas todavía, y eso es intencional. Preferimos construir esto con cuidado antes que precipitarnos en una interfaz que pierda la esencia. Pero la dirección es clara: Glossia debe dar la bienvenida a todos los que se preocupan por hacer hablar al software en todos los idiomas.

## Mantente al tanto

Glossia todavía está en una etapa temprana, y la estamos construyendo de forma abierta. Si esto resuena con cómo piensas sobre la localización, mantente atento al proyecto. Compartiremos más a medida que avancemos.