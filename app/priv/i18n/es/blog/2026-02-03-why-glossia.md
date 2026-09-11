%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para impulsarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen la CI y te atan a ecosistemas de proveedores. Estamos explorando qué forma puede tomar un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, conoces el procedimiento. Eliges una plataforma de localización, la conectas con tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones vuelven y, en algún punto, las cosas se rompen.

Esa sobrecarga, el traslado constante de contenido desde y hacia tu repositorio, es el precio que cada equipo paga por usar las herramientas de localización actuales. Suena a poco hasta que eres tú quien depura por qué un PR de traducción rompió la compilación de tu sitio el viernes a las 6 PM.

## Un diseño heredado desde antes de internet

La mayoría de las plataformas de localización se diseñaron alrededor de conceptos que preceden al flujo de trabajo moderno de desarrollo. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y desconectado. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Migrar a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona por completo.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el cronograma de otro.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No conocen tus linters, tu paso de construcción, tu validador de enlaces ni tu esquema de frontmatter. Empujan el contenido traducido de nuevo a tu repositorio y confían en que funcione. Cuando falla, y lo hace, alguien del equipo tiene que detener lo que está haciendo para arreglar problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias agénticas nos presentan nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, ve el error y reintenta hasta que la salida sea válida. Ese tipo de ciclo de retroalimentación estricto lo cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan en la línea de tiempo de alguien más y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora lleva horas o días. El contexto que la hacía útil se ha perdido. Pierdes el ciclo y, con él, toda la ventaja que los flujos de trabajo agénticos deberían darte.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una experiencia profunda tanto en desarrollo como en localización, lo que trajo claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, la dinámica humana de los equipos de traducción y las razones por las que las herramientas existentes acabaron así fue esencial.

Juntos, continuamos llegando a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLM, sin agentes de codificación y sin pipelines de CI. El modelo completo asumía que la traducción era algo que ocurría fuera del flujo de trabajo de desarrollo y se empujaba de nuevo hacia adentro. Eso tiene sentido hace diez años. Ya no lo hace.

Comenzamos preguntando: **¿y si los agentes de localización pudieran funcionar de la misma manera que los agentes de codificación lo hacen?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa sobre flujos de trabajo de agentes con Claude. El patrón de otorgar acceso a herramientas a un agente, permitiéndole razonar durante una tarea, validar su propia salida e iterar cuando algo falla se ajusta notablemente a la localización. Un agente de traducción que pueda leer tus archivos de origen, entender el contexto del proyecto, generar traducciones, ejecutar tu lintador y corregir problemas antes de abrir una solicitud de extracción. No es una fantasía. Es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Construimos Glossia porque queremos que más software sea localizado, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si tu flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de tarifas por palabra y un responsable de proyecto para coordinar las entregas, la mayoría de los equipos simplemente publicará en inglés y dará por finalizado el día.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Consideramos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo.

En su núcleo, Glossia es un agente. Empezamos con el terminal como su interfaz principal porque es ahí donde se resuelven primero los problemas más difíciles: leer tus archivos de origen, generar traducciones, ejecutar tus comprobaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le permites trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de la localización son desarrolladores. Discutimos esto a menudo internamente. Las personas que más valoran la precisión de la traducción, el tono y los matices culturales suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Aportan el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita mejora. Y el agente gestiona todo lo demás: el commit, la validación y la apertura de la solicitud de incorporación.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construirlo reflexivamente antes que precipitarnos en una interfaz que pierda el punto. Pero la dirección está clara: Glossia debería dar la bienvenida a todos los que se preocupan por hacer que el software hable cada idioma.

## Mantente al tanto

Glossia aún está en sus inicios, y lo estamos construyendo en abierto. Si esto resuena con cómo piensas sobre la localización, mantente atento al proyecto. Compartiremos más a medida que avancemos.