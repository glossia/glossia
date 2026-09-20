%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para llevarla al futuro.",
  summary:
    "Las herramientas de localización tradicionales añaden sobrecarga, fallan la CI y te atan a ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo agéntico de localización.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, conoces el proceso. Eliges una plataforma de localización, la conectas con tu repositorio y luego dedicas el resto de tu tiempo a gestionar la sincronización. El contenido sale, las traducciones vuelven, y en algún punto intermedio las cosas fallan.

Esa sobrecarga, el viaje constante de ida y vuelta del contenido desde y hacia tu repositorio, es el precio que cada equipo paga por usar las herramientas de localización actuales. Suena menor hasta que eres tú el que depura por qué una PR de traducción rompió la compilación de tu sitio a las 6 PM el viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización fueron diseñadas en torno a conceptos que preceden al flujo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Migrar a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona correctamente.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa bajo el horario de alguien más.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No saben de tus linters, tu paso de construcción, tu verificador de enlaces o tu esquema de frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan que todo salga bien. Cuando falla y falla, alguien del equipo tiene que detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias con agentes nos presentan nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y vuelve a intentarlo hasta que la salida sea válida. Ese tipo de bucle de retroalimentación cerrado cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. El momento en que lo envías a una plataforma externa, las traducciones vuelven con otro cronograma y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hacía útil ya ha desaparecido. Pierdes el bucle, y con él, toda la ventaja que se suponía que los flujos de trabajo de agentes te darían.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo que aportó claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, la dinámica humana de los equipos de traducción y las razones por las que las herramientas existentes terminaron tal como lo hicieron fue esencial.

Juntos, llegábamos siempre a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de programación y sin pipelines de CI. El modelo completo asumía que la traducción era algo que ocurría fuera del flujo de desarrollo y se reintroducía después. Eso tenía sentido hace diez años. Ya no lo tiene.

Empezamos a preguntar: **¿qué pasaría si los agentes de localización pudieran funcionar de la misma manera que los agentes de programación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en flujos de trabajo agénticos con Claude. El patrón de permitir acceso a herramientas a un agente, permitiéndole razonar a través de una tarea, validar su propia salida y iterar cuando algo falla encaja notablemente bien con la localización. Un agente de traducción que pueda leer tus archivos fuente, comprender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una pull request. Eso no es una fantasía. Ese es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software.

Creamos Glossia porque queremos que más software esté localizado, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para pequeños equipos, desarrolladores independientes y proyectos secundarios. Si tu flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gerente de proyecto para coordinar entregas, la mayoría de los equipos simplemente lanzarán en inglés y darán por finalizado el día.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo

En su núcleo, Glossia es un agente. Estamos empezando con la terminal como su interfaz principal porque ahí es donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus comprobaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das un terminal y lo dejas trabajar.

Pero el terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Lo discutimos a menudo internamente. Las personas que más se preocupan por la precisión de la traducción, el tono y los matices culturales son a menudo lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente se encarga de todo lo demás: realizar commits, validar y abrir la solicitud de extracción.

Todavía no tenemos todas las respuestas y eso es intencional. Preferimos construir esto de forma reflexiva en lugar de apresurarnos a una interfaz que pierda el objetivo. Pero la dirección es clara: Glossia debería dar la bienvenida a todos quienes se preocupan por hacer que el software hable cada idioma.

## Mantente al tanto

Glossia todavía está en sus inicios, y lo estamos construyendo en abierto. Si esto resuena con cómo piensas sobre la localización, mantente al tanto del proyecto. Compartiremos más a medida que avancemos.