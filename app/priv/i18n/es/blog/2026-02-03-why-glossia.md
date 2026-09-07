%{
  title:
    "La localización se quedó estancada en el pasado. Construimos Glossia para impulsarla hacia adelante.",
  summary:
    "Las herramientas tradicionales de localización añaden sobrecarga, rompen CI y te atrapan en ecosistemas de proveedores. Estamos explorando cómo puede verse un flujo de trabajo de localización agéntico.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez ha lanzado software en más de un idioma, conoce el proceso. Seleccionas una plataforma de localización, la conectas a tu repositorio y luego pasas el resto de tu tiempo gestionando la sincronización. El contenido sale, las traducciones regresan y, en algún punto intermedio, las cosas se rompen.

Ese sobrecoste, el ciclo constante de ida y vuelta del contenido de y hacia tu repositorio, es el impuesto que cada equipo paga por usar las herramientas de localización actuales. Suena menor hasta que eres tú depurando por qué una PR de traducción rompió la compilación de tu sitio a las 6 PM de un viernes.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización fueron diseñadas en torno a conceptos que preceden al flujo de desarrollo moderno. Memorias de traducción. Coincidencia difusa. Traductores humanos trabajando dentro de editores propietarios, apoyados por herramientas que sugieren cadenas similares desde una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y sin conexión. Pero las empresas convirtieron las memorias de traducción en un mecanismo de bloqueo. Tus traducciones pasadas, el conocimiento institucional que pagaste, viven dentro de su plataforma. Moverse a otro proveedor significa empezar de cero, o pagar por una exportación que nunca termina de funcionar.

El resultado es una industria construida sobre fricción artificial. Tu contenido abandona tu repositorio, entra en una caja negra y regresa según el cronograma de alguien más.

## El bucle de retroalimentación roto

El problema es estructural: las herramientas externas de localización no pueden ejecutar tu pipeline de CI. No conocen tus linters, tu paso de compilación, tu verificador de enlaces, ni tu esquema frontmatter. Empujan el contenido traducido de vuelta a tu repositorio y esperan lo mejor. Cuando se rompe, y se rompe, alguien del equipo debe detener lo que está haciendo para corregir problemas de formato, sintaxis rota o marcado no válido que introdujo la herramienta de traducción.

Los LLM y las experiencias agénticas nos están presentando nuevas oportunidades para repensar estos flujos de trabajo por completo. Un agente que genera una traducción, ejecuta tus comprobaciones, ve el error y reintent hasta que la salida es válida. Ese tipo de bucle de retroalimentación estrecho cambia todo.

Pero solo funciona si el contenido permanece donde reside: en tu repositorio. En el momento en que lo envías a una plataforma externa, las traducciones regresan bajo el horario de alguien más y la integración se rompe. La retroalimentación que podría haber sido instantánea ahora toma horas o días. El contexto que la hizo útil ha desaparecido por completo. Pierdes el bucle, y con él, toda la ventaja que los flujos de trabajo agénticos estaban destinados a darte.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron en Glossia por sí solas. El proyecto surgió de una profunda experiencia tanto en desarrollo como en localización, lo que aportó claridad a problemas que son difíciles de ver solo desde un solo lado. Entender los flujos de trabajo lingüísticos, la dinámica humana de los equipos de traducción y las razones por las que las herramientas existentes terminaron así, fue esencial.

Juntos, llegábamos siempre a las mismas observaciones: las herramientas de localización se diseñaron para un mundo sin LLM, sin agentes de codificación y sin pipelines de CI. El modelo entero asumía que la traducción era algo que ocurría fuera del flujo de desarrollo y se empujaba de vuelta para adentro. Eso tenía sentido hace diez años. Ya no lo tiene.

Empezamos a preguntarnos: **¿qué pasaría si los agentes de localización pudieran funcionar de la misma manera que los agentes de código?**

Hemos prestado mucha atención a cómo [Anthropic](https://anthropic.com) piensa sobre los flujos de trabajo agénticos con Claude. El patrón de dar a un agente acceso a herramientas, permitiéndole razonar sobre una tarea, validar su propia salida e iterar cuando algo falla se mapea sorprendentemente bien a la localización. Un agente de traducción que pueda leer tus archivos de origen, entender el contexto del proyecto, generar traducciones, ejecutar tu linter y corregir problemas antes de abrir una solicitud de extracción. Eso no es una fantasía. Eso es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo a la industria del software

Construimos Glossia porque queremos que más software esté localizado, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para pequeños equipos, desarrolladores independientes y proyectos secundarios. Si su flujo de trabajo de traducción requiere un proceso de adquisición, una negociación de precios por palabra y un gestor de proyectos para coordinar las transferencias, la mayoría de los equipos simplemente publicarán en inglés y así se cierra el día.

Glossia utiliza modelos a los que ya tienes acceso. Y valida la salida con tus propias herramientas, no con las nuestras.

Pensamos que la localización debería ser tan natural como ejecutar tu suite de pruebas.

## Un agente primero, interfaces segundo

En su núcleo, Glossia es un agente. Estamos comenzando con la terminal como su interfaz principal porque es allí donde se resuelven primero los problemas más duros: leer tus archivos de origen, generar traducciones, realizar tus comprobaciones y iterar hasta que la salida sea válida. Este es el mismo patrón que siguió [OpenAI](https://openai.com) con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Constrúes el agente, le das una terminal y le dejas trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todos aquellos que contribuyen a la calidad de la localización son desarrolladores. Hablamos de esto a menudo internamente. Las personas que más se preocupan por la exactitud de la traducción, el tono y el matiz cultural suelen ser lingüistas y especialistas en contenido que no piensan en términos de ramas, compilación o JSON.

Es por eso que queremos construir nuevas interfaces sobre el mismo agente. Algo donde un lingüista ve el contenido, el contexto y la traducción lado a lado. Llevan el juicio humano que ningún modelo puede reemplazar. Mejoran lo que necesita refinamiento. Y el agente maneja todo lo demás: el commit, la validación y abrir el pull request.

Todavía no tenemos todas las respuestas, y eso es intencional. Preferimos construir esto de manera reflexiva que apresurarnos en una interfaz que no logra el objetivo. Pero la dirección es clara: Glossia debe dar la bienvenida a todos los que se preocupan por hacer que el software hable cada idioma.

## Manténganse pendientes

Glossia está aún en etapas tempranas, y lo estamos construyendo públicamente. Si esto resuena con tu forma de pensar sobre la localización, mantén un ojo en el proyecto. Compartiremos más a medida que avancemos.