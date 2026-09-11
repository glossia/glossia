%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para impulsarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen CI y te encierran en ecosistemas de proveedores. Estamos explorando qué aspecto puede tener un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has distribuido software en más de un idioma, sabes de qué va todo. Eliges una plataforma de localización, la conectas a tu repositorio y dedicas el resto del tiempo a gestionar la sincronización. El contenido sale, las traducciones regresan y entre medias algo se rompe.

Esa sobrecarga, esa constante ida y vuelta del contenido hacia y desde tu repositorio, es el coste que cada equipo paga por usar las herramientas de localización actuales. Parece menor hasta que eres tú el que depura por qué un PR de traducción rompió la compilación de tu sitio a las 6 de la tarde del viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos anteriores al flujo de trabajo moderno de desarrollo. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, respaldados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Cambiar a otro proveedor significa empezar desde cero, o pagar por una exportación que nunca funciona bien.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el horario de alguien más.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No tienen en cuenta tus linters, tu paso de compilación, tu comprobador de enlaces o tu esquema frontmatter. Devuelven el contenido traducido a tu repositorio y esperan lo mejor. Cuando se rompe, y lo hacen, alguien del equipo tiene que detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que introdujo la herramienta de traducción.

Los LLMs y las experiencias basadas en agentes nos presentan nuevas oportunidades para repensar completamente estos flujos de trabajo. Un agente que genera una traducción, ejecuta tus verificaciones, detecta el error y vuelve a intentarlo hasta que la salida sea válida. Ese tipo de bucle de retroalimentación ajustado cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En cuanto lo envías a una plataforma externa, las traducciones se devuelven según el cronograma de otro, y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora toma horas o días. El contexto que la hacía útil ya se ha ido. Pierdes el bucle, y con él, toda la ventaja que se supone que los flujos de trabajo con agentes podían ofrecerte.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo que aportó claridad a problemas difíciles de ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas existentes terminaron así fue esencial.

Juntos, seguíamos llegando a las mismas observaciones: las herramientas de localización se diseñaron para un mundo sin LLMs, sin agentes de código, y sin pipelines de CI. El modelo completo asumía que la traducción ocurría fuera del flujo de desarrollo y se empujaba hacia adentro. Eso tenía sentido hace diez años. Ya no es así.

Empezamos a preguntar: **¿Y si los agentes de localización pudieran trabajar de la misma manera que los agentes de código?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en flujos de trabajo agénticos con Claude. El patrón de dar a un agente acceso a herramientas, permitirle razonar sobre una tarea, validar su propia salida e iterar cuando algo va mal se ajusta notablemente bien a la localización. Un agente de traducción que pueda leer tus archivos fuente, entender el contexto del proyecto, generar traducciones, ejecutar tu linteador y corregir problemas antes de abrir una solicitud de cambio. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Hemos construido Glossia porque queremos que más software sea localizado, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para pequeños equipos, desarrolladores independientes y proyectos personales. Si tu flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyecto para coordinar las entregas, la mayoría de los equipos simplemente lo lanzará en inglés y lo dejará ahí.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo.

En su núcleo, Glossia es un agente. Estamos empezando con el terminal como su interfaz principal porque es allí donde los problemas más difíciles se resuelven primero: leyendo tus archivos de origen, generando traducciones, ejecutando tus comprobaciones e iterando hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le permites trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos quienes contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas que se preocupan más por la precisión en la traducción, el tono y los matices culturales son a menudo lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Traen el juicio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinarse. Y el agente gestiona todo lo demás: realizar commits, validar y abrir la solicitud de extracción.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto con meditación que precipitarnos en una interfaz que pierda el punto. Pero la dirección es clara: Glossia debería dar la bienvenida a todos los que se preocupan por hacer que el software hable todos los idiomas.

## Mantente al tanto

Glossia aún está en etapa temprana, y lo estamos construyendo en abierto. Si algo de esto resuena con cómo piensas sobre la localización, mantén un ojo en el proyecto. Compartiremos más a medida que avancemos.