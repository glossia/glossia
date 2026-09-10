%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para impulsarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen el CI y te atan a los ecosistemas de proveedores. Estamos explorando qué aspecto puede tener un flujo de trabajo de localización basado en agentes.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez ha lanzado software en más de un idioma, sabes lo que hay. Eliges una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven y en algún punto las cosas se rompen.

Ese sobrecargo, el viaje constante de contenido hacia y desde tu repositorio, es la factura que todo equipo paga por usar las herramientas de localización actuales. Suena menor hasta que tú estás depurando por qué una PR de traducción rompió la construcción del sitio a las 6 de la tarde de un viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos que preceden al flujo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, respaldados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual, fuera de línea. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona del todo.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el calendario de alguien más.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No saben nada de tus linters, de tu paso de construcción, de tu comprobador de enlaces o de tu esquema de frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan lo mejor. Cuando falla, y falla, alguien del equipo tiene que detenerse para corregir problemas de formato, sintaxis rota o marcado inválido que la herramienta de traducción introdujo.

Los LLM y las experiencias agénticas nos presentan nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y lo vuelve a intentar hasta que la salida sea válida. Ese tipo de bucle de retroalimentación ajustado cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan en la línea de tiempo de otra persona, y la integración falla. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hacía útil ya no existe. Pierdes el bucle, y con él, toda la ventaja que se suponía que los flujos de trabajo agénticos debían darte.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una experiencia profunda tanto en desarrollo como en localización, lo que trajo claridad a problemas difíciles de ver solo desde un lado. Comprender los flujos de trabajo lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes terminaron de esa manera era esencial.

Juntos, seguimos llegando a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLM, sin agentes de codificación y sin pipelines de CI. El modelo entero asumía que la traducción era algo que ocurría fuera del flujo de trabajo de desarrollo y se empujaba hacia adentro. Eso tenía sentido hace diez años. Ahora ya no es así.

Empezamos a preguntar: **¿qué pasaría si los agentes de localización pudieran trabajar de la misma manera que los agentes de codificación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en flujos de trabajo de agentes con Claude. El patrón de otorgar acceso a herramientas a un agente, permitirle razonar sobre una tarea, validar su propia salida e iterar cuando algo va mal encaja sorprendentemente bien con la localización. Un agente de traducción que pueda leer tus archivos de origen, entender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir un pull request. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo a la industria del software

Construimos Glossia porque queremos que más software sea localizado, no menos.

Los procesos complejos y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si su flujo de trabajo de traducción requiere un proceso de adquisiciones, una negociación de precios por palabra y un gerente de proyecto para coordinar las entregas, la mayoría de los equipos simplemente lanzará en inglés y considerará el asunto concluido.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces después.

En su núcleo, Glossia es un agente. Estamos comenzando con el terminal como su interfaz principal porque es allí donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus verificaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas que más se preocupan por la precisión de la traducción, el tono y la sutileza cultural son a menudo lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Es por ello que queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista vea el contenido, el contexto y la traducción lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente se encarga de todo lo demás: el commit, validar, abrir el pull request.

Todavía no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto de manera reflexiva antes que apresurarnos a una UI que pierda la idea. Pero la dirección está clara: Glossia debe dar la bienvenida a todos aquellos que desean hacer que el software hable cada idioma.

## Mantente atento

Glossia todavía está en una etapa temprana, y lo estamos construyendo en abierto. Si esto resuena con tu forma de pensar sobre la localización, mantente al tanto del proyecto. Compartiremos más a medida que avancemos.