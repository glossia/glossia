%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para impulsarla hacia el futuro.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen la CI y te confinan en ecosistemas de proveedores. Estamos explorando cómo podría verse un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez ha lanzado software en más de un idioma, sabe cómo va. Elige una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, vuelven las traducciones y, en algún punto intermedio, las cosas se rompen.

Esa sobrecarga, el viaje de ida y vuelta constante del contenido hacia y desde tu repositorio, es el coste que cada equipo paga por usar las herramientas de localización de hoy. Parece insignificante hasta que eres tú el que depura por qué una PR de traducción rompió la compilación de tu sitio a las 6 de la tarde del viernes.

## Un diseño heredado anterior a internet

La mayoría de las plataformas de localización fueron diseñadas en torno a conceptos que preceden al flujo de trabajo moderno de desarrollo. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas de texto similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual, sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de atadura. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar de cero, o pagar por una exportación que nunca funciona del todo.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa con el horario de un tercero.

## El ciclo de retroalimentación roto

El problema es estructural: las herramientas externas de localización no pueden ejecutar tu pipeline de CI. No tienen conocimiento de tus linters, tu paso de compilación, tu verificador de enlaces, o tu esquema frontmatter. Devuelven el contenido traducido a tu repositorio y esperan lo mejor. Cuando se rompe, y lo hace, alguien del equipo tiene que detener lo que está haciendo para solucionar problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias agénticas nos presentan nuevas oportunidades para replantear por completo estos flujos de trabajo. Un agente que genera una traducción, ejecuta tus comprobaciones, ve el error y vuelve a intentarlo hasta que la salida sea válida. Ese tipo de ciclo de retroalimentación estricto cambia todo.

Però solo funciona si el contenido se mantiene donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones vuelven en el cronograma de alguien más y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora tarda horas o días. El contexto que la hacía útil se ha ido. Pierdes el ciclo, y con él, toda la ventaja que los flujos de trabajo agénticos debían proporcionarte.

## Observaciones que moldearon a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en el desarrollo como en la localización, lo que trajo claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes terminaron así fue esencial.

Juntos, seguimos llegando a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de codificación y sin pipelines de CI. El modelo entero asumía que la traducción era algo que ocurría fuera del flujo de trabajo de desarrollo y se reintroducía después. Eso tenía sentido hace diez años. Ya no lo es.

Comenzamos a preguntarnos: **¿Qué pasaría si los agentes de localización pudieran funcionar de la misma forma que los agentes de codificación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en flujos de trabajo de agentes con Claude. El patrón de dar a un agente acceso a herramientas, permitirle razonar a través de una tarea, validar su propia salida e iterar cuando algo falla se ajusta maravillosamente bien a la localización. Un agente de traducción que pueda leer tus archivos fuente, comprender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una pull request. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Creamos Glossia porque queremos que más software sea localizado, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si tu flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyecto para coordinar las entregas, la mayoría de los equipos simplemente publicará en inglés y dará por finalizado el día.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces en segundo lugar

En su núcleo, Glossia es un agente. Estamos empezando con la terminal como su interfaz principal porque es donde se resuelven primero los problemas más difíciles: leyendo tus archivos de origen, generando traducciones, ejecutando comprobaciones e iterando hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y dejas que funcione.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto frecuentemente internamente. Las personas que más se preocupan por la precisión de la traducción, el tono y los matices culturales suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Esa es la razón por la que queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Llevan el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente maneja todo lo demás: realizar el commit, validar, abrir la solicitud de extracción.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto con cuidado antes de precipitarnos en una interfaz que no logre el objetivo. Pero la dirección es clara: Glossia debe dar la bienvenida a todos los que se preocupan por hacer que el software hable todos los idiomas.

## Mantente al tanto

Glossia aún está en una etapa temprana y la construimos de forma abierta. Si esto resuena con cómo piensas sobre la localización, mantente al tanto del proyecto. Compartiremos más a medida que avancemos.