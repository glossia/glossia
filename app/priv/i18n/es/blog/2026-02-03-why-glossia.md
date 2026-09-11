%{
  title:
    "La localización se quedó estancada en el pasado. Creamos Glossia para impulsarla hacia el futuro.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen la CI y te atan a ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, conoces el procedimiento. Eliges una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven y, en algún punto intermedio, las cosas fallan.

Esa sobrecarga, el intercambio constante de contenido desde y hacia tu repositorio, es el impuesto que cada equipo paga por usar las herramientas de localización actuales. Suena menor hasta que eres tú depurando por qué una PR de traducción rompió la construcción de tu sitio a las 6 PM del viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos que anteceden a los flujos de trabajo de desarrollo modernos. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tuvieron sentido cuando la traducción era un proceso manual y offline. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Cambiarse a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona correctamente.

El resultado es una industria construida sobre fricción artificial. Tu contenido abandona tu repositorio, entra en una caja negra y vuelve según el horario de otra persona.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No conocen tus linters, tu paso de compilación, tu verificador de enlaces, ni tu esquema de frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan lo mejor de lo mejor. Cuando falla, y cuando falla, alguien del equipo tiene que detener lo que está haciendo para solucionar problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias de agentes nos presentan nuevas oportunidades para repensar por completo estos flujos de trabajo. Un agente que genera una traducción, ejecuta tus verificaciones, detecta el error y reintentará hasta que el resultado sea válido. Ese tipo de bucle cerrado de retroalimentación cambia todo.

Pero solo funciona si el contenido se queda donde reside: en tu repositorio. El momento en que lo envías a una plataforma externa, las traducciones vuelven en la línea de tiempo de alguien más y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hizo útil ya ha desaparecido. Pierdes el bucle y, con él, toda la ventaja que los flujos de trabajo de agentes debían ofrecerte.

## Observaciones que dieron forma a Glossia

Estas frustraciones no dieron forma a Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo cual trajo claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, la dinámica humana de los equipos de traducción y las razones por las que las herramientas existentes terminaron así fue esencial.

Juntos, llegamos a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de codificación y sin pipelines de CI. El modelo entero asumía que la traducción sucedía fuera del flujo de desarrollo y se empujaba hacia atrás. Eso tenía sentido hace diez años. Ya no lo tiene.

Comenzamos a preguntarnos: **¿Qué pasaría si los agentes de localización pudieran funcionar igual que los agentes de codificación?**

Hemos estado prestando atención a cómo [Anthropic](https://anthropic.com) piensa sobre flujos de trabajo agénticos con Claude. El patrón de dar a un agente acceso a herramientas, permitiéndole razonar a través de una tarea, validar su propia salida e iterar cuando algo falla, se ajusta notablemente bien con la localización. Un agente de traducción que pueda leer tus archivos de origen, entender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una solicitud de extracción. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Construimos Glossia porque queremos que más software se traduzca, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si su flujo de trabajo de traducción requiere un proceso de adquisiciones, una negociación de precios por palabra y un gestor de proyectos para coordinar las transferencias, la mayoría de los equipos simplemente publicará en inglés y cerrará el asunto.

Glossia utiliza modelos a los que ya tienes acceso. Además, valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces después.

En el núcleo, Glossia es un agente. Estamos empezando con la terminal como su interfaz principal porque es allí donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus comprobaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y lo dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas que más se preocupan por la precisión de la traducción, el tono y los matices culturales suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita ser refinado. Y el agente se encarga del resto: realizar el commit, validar y abrir la solicitud de extracción.

Aún no tenemos todas las respuestas y eso es intencional. Preferimos construir esto de manera reflexiva antes que precipitarnos hacia una interfaz que no acierte el objetivo. Pero la dirección es clara: Glossia debería dar la bienvenida a todos los que se preocupan por hacer que el software hable cada idioma.

## Mantente al día

Glossia aún está en una etapa temprana, y la estamos construyendo en abierto. Si esto resuena con tu forma de pensar sobre la localización, mantén un ojo puesto en el proyecto. Compartiremos más a medida que avancemos.