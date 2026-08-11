%{
  title: "La localización estaba estancada en el pasado. Creamos Glossia para hacerla avanzar.",
  summary: "Las herramientas de localización tradicionales añaden trabajo, interrumpen la integración continua y le atan a ecosistemas de proveedores. Estamos explorando cómo puede ser un flujo de localización basado en agentes.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si alguna vez ha lanzado software en más de un idioma, ya conoce el proceso. Elige una plataforma de localización, la conecta a su repositorio y dedica el resto del tiempo a gestionar la sincronización. El contenido sale, las traducciones vuelven y, en algún punto intermedio, algo falla.

Esa sobrecarga, el constante trasiego de contenido desde y hacia su repositorio, es el coste que todos los equipos pagan por utilizar las herramientas de localización actuales. Parece algo menor hasta que le toca averiguar por qué una solicitud de cambios de traducción rompió la compilación de su sitio un viernes a las 18:00.

## Un diseño heredado de antes de internet

La mayoría de las plataformas de localización se diseñaron en torno a conceptos anteriores al flujo de trabajo de desarrollo moderno. Memorias de traducción. Coincidencias aproximadas. Traductores humanos que trabajan en editores propietarios, con herramientas que sugieren cadenas similares procedentes de una base de datos.

Estas ideas tenían sentido cuando la traducción era un proceso manual y sin conexión. Sin embargo, las empresas convirtieron las memorias de traducción en un mecanismo de dependencia del proveedor. Sus traducciones anteriores, el conocimiento institucional por el que pagó, permanecen dentro de su plataforma. Cambiar de proveedor implica empezar desde cero o pagar por una exportación que nunca termina de funcionar correctamente.

El resultado es una industria basada en fricciones artificiales. Su contenido sale del repositorio, entra en una caja negra y vuelve según los plazos de otra empresa.

## El ciclo de retroalimentación roto

El problema es estructural: las herramientas externas de localización no pueden ejecutar su pipeline de integración continua. Desconocen sus analizadores de código, su proceso de compilación, su verificador de enlaces y el esquema de sus metadatos iniciales. Envían el contenido traducido de vuelta a su repositorio y esperan que todo salga bien. Cuando algo falla, y ocurre, alguien del equipo debe interrumpir su trabajo para corregir problemas de formato, errores de sintaxis o marcado no válido introducido por la herramienta de traducción.

Los modelos de lenguaje de gran tamaño y las experiencias basadas en agentes nos brindan nuevas oportunidades para replantear por completo estos flujos de trabajo. Un agente puede generar una traducción, ejecutar sus comprobaciones, detectar el error y volver a intentarlo hasta que el resultado sea válido. Este tipo de ciclo de retroalimentación inmediato lo cambia todo.

Sin embargo, solo funciona si el contenido permanece donde reside: en su repositorio. En cuanto se envía a una plataforma externa, las traducciones vuelven según los plazos de otra empresa y la integración se rompe. La retroalimentación que podría haber sido instantánea pasa a tardar horas o días. El contexto que la hacía útil ya se ha perdido. Se pierde el ciclo y, con él, toda la ventaja que debían aportar los flujos de trabajo basados en agentes.

## Observaciones que dieron forma a Glossia

Estas frustraciones no se convirtieron por sí solas en Glossia. El proyecto surgió de una amplia experiencia tanto en desarrollo como en localización, lo que permitió comprender con claridad problemas difíciles de detectar desde una sola perspectiva. Fue esencial entender los flujos de trabajo lingüísticos, las dinámicas humanas de los equipos de traducción y las razones por las que las herramientas actuales acabaron siendo como son.

Una y otra vez llegamos a las mismas observaciones: las herramientas de localización se diseñaron para un mundo sin modelos de lenguaje de gran tamaño, sin agentes de programación y sin pipelines de integración continua. Todo el modelo asumía que la traducción ocurría fuera del flujo de trabajo de desarrollo y después se incorporaba de nuevo. Eso tenía sentido hace diez años. Ya no.

Empezamos a preguntarnos: **¿qué ocurriría si los agentes de localización pudieran trabajar igual que los agentes de programación?**

Hemos seguido muy de cerca cómo [Anthropic](https://anthropic.com) aborda los flujos de trabajo basados en agentes con Claude. El patrón de dar a un agente acceso a herramientas, permitirle razonar sobre una tarea, validar su propio resultado e iterar cuando algo no es correcto encaja extraordinariamente bien con la localización. Un agente de traducción capaz de leer sus archivos de origen, comprender el contexto del proyecto, generar traducciones, ejecutar su analizador y corregir los problemas antes de abrir una solicitud de incorporación de cambios. No es una fantasía. Es el flujo de trabajo que estamos construyendo.

## Glossia es nuestro regalo para la industria del software

Creamos Glossia porque queremos que se localice más software, no menos.

Los procesos complicados y las plataformas costosas hacen que la localización sea inaccesible para equipos pequeños, desarrolladores independientes y proyectos personales. Si su flujo de trabajo de traducción requiere un proceso de compras, una negociación de precios por palabra y un jefe de proyecto que coordine las entregas, la mayoría de los equipos simplemente publicará el producto en inglés y dará el trabajo por terminado.

Glossia utiliza modelos a los que ya tiene acceso. Además, valida el resultado con sus propias herramientas, no con las nuestras.

Creemos que la localización debería ser tan natural como ejecutar su conjunto de pruebas.

## Primero el agente, después las interfaces

En esencia, Glossia es un agente. Empezamos con la terminal como interfaz principal porque es donde primero se resuelven los problemas más difíciles: leer sus archivos de origen, generar traducciones, ejecutar sus comprobaciones e iterar hasta que el resultado sea válido. Este es el mismo enfoque que siguieron [OpenAI](https://openai.com) con [Codex](https://openai.com/index/openai-codex/) y [Anthropic](https://anthropic.com) con [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Se crea el agente, se le proporciona una terminal y se le deja trabajar.

Pero la terminal es solo la primera interfaz, no la única. Sabemos que no todas las personas que contribuyen a la calidad de la localización son desarrolladoras. Hablamos de ello a menudo internamente. Quienes más se preocupan por la precisión de las traducciones, el tono y los matices culturales suelen ser lingüistas y especialistas en contenidos que no piensan en términos de ramas, compilación o JSON.

Por eso queremos crear nuevas interfaces sobre el mismo agente. Una interfaz en la que el lingüista vea el contenido, el contexto y la traducción en paralelo. Aporta el criterio humano que ningún modelo puede sustituir. Perfecciona lo que necesita ajustes. Y el agente se encarga de todo lo demás: crear el commit, validar y abrir la solicitud de incorporación de cambios.

Aún no tenemos todas las respuestas, y es intencionado. Preferimos crear esto con cuidado antes que apresurarnos a lanzar una interfaz de usuario que no cumpla su propósito. Pero la dirección está clara: Glossia debe acoger a todas las personas interesadas en hacer que el software hable todos los idiomas.

## Manténgase al tanto

Glossia aún se encuentra en una fase inicial y lo estamos desarrollando de forma abierta. Si alguna de estas ideas coincide con su forma de entender la localización, siga de cerca el proyecto. Compartiremos más información a medida que avancemos.