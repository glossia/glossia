%{
  title:
    "La localización se había quedado estancada en el pasado. Construimos Glossia para impulsarla hacia adelante.",
  summary:
    "Las herramientas de localización tradicionales añaden sobrecarga, rompen la CI y te atan a ecosistemas de proveedores. Estamos explorando qué puede ser un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, conoces el proceso. Eliges una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones regresan, y en algún punto intermedio las cosas se rompen.

Esa sobrecarga, la ida y vuelta constante de contenido hacia y desde tu repositorio, es el coste que cada equipo paga por utilizar las herramientas de localización actuales. Parece menor hasta que tú eres quien depura por qué una PR de traducción rompió la construcción de tu sitio a las 6 de la tarde del viernes.

## Un diseño heredado de antes de internet.

La mayoría de las plataformas de localización se diseñaron en torno a conceptos que preceden al flujo de trabajo moderno de desarrollo. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y desconectado. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar de cero, o pagar por una exportación que nunca funciona del todo.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el horario de alguien más.

## El bucle de retroalimentación roto.

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No conocen tus linters, tu etapa de construcción, tu verificador de enlaces ni tu esquema de frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan lo mejor. Cuando falla, y así es, alguien del equipo tiene que detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que la herramienta de traducción introdujo.

Las LLMs y las experiencias basadas en agentes nos presentan nuevas oportunidades para replantear estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, ve el error y reintentará hasta que la salida sea válida. Ese tipo de ciclo de retroalimentación ajustado cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan en el cronograma de un tercero y la integración falla. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hacía útil ya desapareció. Pierdes el bucle y, con él, toda la ventaja que los flujos de trabajo basados en agentes deberían haberte dado.

## Observaciones que moldearon a Glossia

Estas frustraciones no se transformaron en Glossia por sí solas. El proyecto surgió de una experiencia profunda tanto en desarrollo como en localización, lo que trajo claridad a problemas difíciles de entender desde una sola perspectiva. Comprender los flujos lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes acabaron siendo como fueron fue esencial.

Juntos, continuamos llegando a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de codificación y sin pipelines de CI. Todo el modelo asumía que la traducción ocurría fuera del flujo de trabajo de desarrollo y se reintroducía después. Eso tenía sentido hace diez años. Ahora ya no lo es.

Comenzamos a preguntar: **¿qué pasa si los agentes de localización pudieran funcionar de la misma manera que los agentes de codificación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa sobre flujos de trabajo agénticos con Claude. El patrón de conceder acceso a herramientas a un agente, permitiéndole razonar a través de una tarea, validar su propia salida e iterar cuando algo falla se ajusta notablemente bien con la localización.

## Glossia es nuestro regalo para la industria del software

Construimos Glossia porque queremos más software localizado, no menos.

Los procesos complejos y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si tu flujo de trabajo de traducción requiere un proceso de compras, una negociación de precios por palabra y un gestor de proyectos para coordinar las transferencias, la mayoría de los equipos simplemente lanzarán en inglés y lo dejarán por hoy.

Glossia utiliza modelos a los que ya tienes acceso. Además, valida la salida con tus propias herramientas, no las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo

En su esencia, Glossia es un agente. Estamos empezando con la terminal como su interfaz principal porque allí es donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus comprobaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le permites trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos quienes contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas a las que más les importa la precisión de la traducción, el tono y los matices culturales suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Es por eso que queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente se encarga de todo lo demás: commit, validación, apertura del pull request.

Todavía no tenemos todas las respuestas y eso es intencional. Preferimos construir esto de manera reflexiva antes que precipitarnos en una interfaz que falte al propósito. Pero la dirección es clara: Glossia debe dar la bienvenida a todos los que se preocupan por hacer que el software hable cada idioma.

## Mantente al tanto

Glossia aún está en sus inicios, y lo estamos construyendo en abierto. Si esto resuena con cómo piensas sobre la localización, mantente pendiente del proyecto. Compartiremos más a medida que avancemos.