%{
  title: "La localización se había quedado estancada en el pasado. Creamos Glossia para avanzar.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen CI y te atan a ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, conoces el procedimiento. Eliges una plataforma de localización, la conectas a tu repositorio y luego dedicas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven, y en algún punto las cosas se rompen.

Esa sobrecarga, el ida y vuelta constante de contenido hacia y desde tu repositorio, es el impuesto que cada equipo paga por usar las herramientas de localización de hoy en día. Suena menor hasta que eres tú quien depura por qué un PR de traducción rompió la compilación de tu sitio a las 6 PM del viernes.

## Un diseño heredado de antes de Internet

La mayoría de las plataformas de localización fueron diseñadas en torno a conceptos que preceden al flujo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, con herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual, fuera de línea. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona correctamente.

El resultado es una industria construida sobre fricción artificial. Tu contenido deja tu repositorio, entra en una caja negra y vuelve según el horario de otra persona.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No saben sobre tus linters, tu paso de compilación, tu verificador de enlaces o tu esquema de frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan lo mejor. Cuando falla, y falla, alguien del equipo tiene que detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias de agentes nos presentan nuevas oportunidades para repensar por completo estos flujos de trabajo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y reintenta hasta que el resultado sea válido. Ese tipo de ciclo de retroalimentación estrecho cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. El momento en que lo envías a una plataforma externa, las traducciones regresan en un cronograma ajeno, y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hacía útil se ha ido. Pierdes el ciclo, y con él, toda la ventaja que los flujos de trabajo de agentes estaban destinados a ofrecerte.

## Observaciones que moldearon Glossia

Estas frustraciones no se transformaron en Glossia por sí solas. El proyecto nació de una experiencia profunda tanto en el desarrollo como en la localización, lo cual aportó claridad a problemas difíciles de discernir desde una sola perspectiva. Comprender los flujos lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes llegaron a ser así fue esencial.

Juntos, llegamos a las mismas observaciones: las herramientas de localización estaban diseñadas para un mundo sin LLMs, sin agentes de código y sin pipelines de CI. El modelo completo asumía que la traducción era algo que ocurría fuera del flujo de desarrollo y se reintroducía después. Eso tenía sentido hace diez años. Ya no lo tiene.

Comenzamos a preguntarnos: **¿Y si los agentes de localización pudieran trabajar de la misma manera que los agentes de código?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en los flujos de trabajo con agentes con Claude. El patrón de dar acceso a un agente a herramientas, permitirle que razonara a través de una tarea, validar su propia salida e iterar cuando algo va mal, se ajusta de manera notable a la localización. Un agente de traducción que pueda leer tus archivos de origen, comprender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una pull request. Eso no es una fantasía. Ese es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Creamos Glossia porque queremos que más software esté localizado, no menos.

Los procesos complejos y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si tu flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyectos para coordinar los traspasos, la mayoría de los equipos simplemente publicará en inglés y considerará la tarea concluida.

Glossia utiliza modelos a los que ya tienes acceso. Y valida el resultado con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo

En su núcleo, Glossia es un agente. Empezamos con la terminal como su interfaz principal porque es allí donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus comprobaciones e iterar hasta que el resultado sea válido. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le permites trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas a quienes más les importa la precisión de la traducción, el tono y el matiz cultural suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción de lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente maneja todo lo demás: commits, validaciones y el pull request.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto con cuidado antes que precipitarnos en una UI que pierda el objetivo. Pero la dirección es clara: Glossia debería dar la bienvenida a todos quienes se preocupan por hacer que el software hable cada idioma.

## Mantente al tanto

Glossia aún está en sus inicios, y la estamos construyendo de forma abierta. Si esto resuena con cómo piensas sobre la localización, mantente atento al proyecto. Compartiremos más a medida que avanzemos.