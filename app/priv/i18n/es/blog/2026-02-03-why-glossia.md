%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para llevarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen la CI y te atan a ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo de localización autónomo.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez has lanzado software en más de un idioma, sabes la dinámica. Eliges una plataforma de localización, la conectas con tu repositorio y luego pasas el resto del tiempo gestionando la sincronización. El contenido sale, las traducciones regresan, y en algún punto las cosas se rompen.

Esa sobrecarga, el constante flujo de ida y vuelta del contenido hacia y desde tu repositorio, es el impuesto que cada equipo paga por utilizar las herramientas de localización actuales. Parece menor hasta que te toca depurar por qué una PR de traducción rompió la construcción de tu sitio a las 6 de la tarde del viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización fueron diseñadas en torno a conceptos que preceden al flujo de trabajo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares de una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y fuera de línea. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional por el que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar desde cero, o pagar por una exportación que rara vez funciona correctamente.

El resultado es una industria construida sobre fricción artificial. Tu contenido sale de tu repositorio, entra en una caja negra y regresa según el horario de un tercero.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas de localización externas no pueden ejecutar tu pipeline de CI. No tienen conocimiento de tus linters, tu paso de construcción, tu verificador de enlaces ni de tu esquema frontmatter. Devuelven contenido traducido a tu repositorio y esperan lo mejor. Cuando falla, y sucede, alguien del equipo debe dejar lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado inválido que la herramienta de traducción introdujo.

Las LLMs y las experiencias agénticas nos presentan nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, detecta el error y vuelve a intentarlo hasta que la salida sea válida. Ese tipo de bucle de retroalimentación cerrado cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan en el cronograma de otra persona, y la integración se rompe. La retroalimentación que habría sido instantánea ahora tarda horas o días. El contexto que la hacía útil ya no existe. Pierdes el bucle, y con él, toda la ventaja que los flujos de trabajo agénticos debían ofrecerte.

## Observaciones que moldearon a Glossia

Estas frustraciones no surgieron como Glossia por sí solas. El proyecto nació de una experiencia profunda tanto en desarrollo como en localización, lo que trajo claridad a problemas que es difícil ver desde un solo lado. Comprender los flujos de trabajo lingüísticos, la dinámica humana de los equipos de traducción y las razones por las que las herramientas existentes terminaron como terminaron fue esencial.

En conjunto, siempre llegábamos a las mismas observaciones: las herramientas de localización fueron diseñadas para un mundo sin LLMs, sin agentes de programación y sin pipelines de CI. El modelo entero asumía que la traducción era algo que ocurría fuera del flujo de desarrollo y se reintroducía después. Eso tenía sentido hace diez años. Ahora no lo hace.

Empezamos a preguntarnos: **¿Qué pasaría si los agentes de localización funcionaran de la misma manera que los agentes de programación?**

Hemos estado prestando mucha atención a cómo [Anthropic](https://anthropic.com) piensa en los flujos de trabajo de agentes con Claude. El patrón de dar a un agente acceso a herramientas, permitirle razonar a través de una tarea, validar su propia salida e iterar cuando algo falla encaja notablemente bien con la localización. Un agente de traducción que pueda leer tus archivos fuente, comprender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una solicitud de extracción. Eso no es una fantasía. Ese es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Creamos Glossia porque queremos que más software esté localizado, no menos.

Los procesos complejos y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos secundarios. Si tu flujo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyecto para coordinar las entregas, la mayoría de los equipos simplemente lanzarán en inglés y considerarán el asunto terminado.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo

En su núcleo, Glossia es un agente. Estamos empezando con la terminal como su interfaz principal porque es donde se resuelven primero los problemas más difíciles: leer tus archivos fuente, generar traducciones, ejecutar tus comprobaciones e iterar hasta que la salida sea válida. Este es el mismo patrón que [OpenAI](https://openai.com) siguió con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construyes el agente, le das una terminal y le dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos los que contribuyen a la calidad de localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas a las que más les importa la precisión de la traducción, el tono y los matices culturales son a menudo lingüistas y especialistas en contenidos que no piensan en términos de ramas, compilación o JSON.

Por eso queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Aportan el criterio humano que ningún modelo puede reemplazar. Refinan lo que necesita refinamiento. Y el agente se encarga del resto: hacer commits, validar y abrir la solicitud de extracción.

Aún no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto con cuidado en lugar de apresurarnos a implementar una interfaz que pierda el propósito. Pero la dirección es clara: Glossia debería dar la bienvenida a todos los que se preocupan por hacer que el software hable todos los idiomas.

## Manténganse al día

Glossia aún está en sus inicios, y lo estamos construyendo en abierto. Si algo de esto resuena con cómo piensan sobre la localización, mantengan un ojo en el proyecto. Compartiremos más a medida que avancemos.