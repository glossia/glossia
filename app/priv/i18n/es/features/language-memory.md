%{
  title: "Memoria lingüística",
  summary:
    "Una capa de contexto versionada que captura la voz, la terminología y el estilo de su organización. La memoria lingüística guía cada flujo de trabajo de agentes y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionada y auditable",
      description:
        "Cada cambio en su voz o terminología crea una nueva versión inmutable. Puede revisar el historial, comparar iteraciones y revertir si algo se desvía.",
      icon: "git-branch"
    },
    %{
      title: "Más allá de la localización",
      description:
        "La memoria lingüística no es solo para la localización. Úsela para generar textos de marketing, redactar documentación, revisar solicitudes de extracción o crear publicaciones sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria lingüística a través de la API REST o del servidor MCP. Incorpóreala en sus propios pipelines de CI, herramientas de contenido o agentes personalizados para mantener la coherencia en todo lo que escriba.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de idiomas?

La memoria de idiomas es el contexto acumulado que indica a los agentes de Glossia cómo comunica tu organización. Está compuesta por dos primitivas fundamentales que creas y refinás con el tiempo:

**Voz** define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices libres viven aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para localidades individuales, de modo que tu contenido en japonés pueda ser más formal mientras tu inglés permanezca conversacional.

**Terminología** define el significado de los términos y cómo deben localizarse. Cada entrada lleva una definición y traducciones por localidad. Cuando un agente encuentra "workspace" en tu contenido fuente, la terminología le indica si debe localizar, transliterar o dejarlo intacto, y exactamente qué palabra usar en cada idioma objetivo.

Juntas, la voz y la terminología forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesitará tu salida.

## Versionamiento inmutable

La memoria de idiomas permite solo el anexo. Cuando actualizes tu voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la antigua. Cada versión registra quién la creó, cuándo, y una nota de cambio opcional que explica qué evolucionó.

Esto significa que siempre tienes un registro de auditoría completo. Puedes comparar la versión 3 contra la versión 7 para entender cómo cambió tu tono durante un trimestre. Si un cambio reciente introdujo inconsistencias, devuelve a una versión anterior y continúa.

El versionamiento también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por los conflictos, ya que cada cambio es un evento discreto y rastreable.

## Resolución sensible a las localidades

Cuando un agente ejecuta un flujo de trabajo para una localidad específica, Glossia resuelve la memoria de idiomas para ese contexto. Comienza con la configuración de voz base y luego aplica cualquier sobrescritura específica de la localidad. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para la localidad objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesitas mantener configuraciones separadas por idioma. Define tus valores predeterminados una vez, sobrescribe donde importa y deja que el sistema de resolución maneje lo demás.

## Úsalo en todos lados

La memoria de idiomas fue diseñada para la localización, pero es útil en cualquier lugar donde produzcas texto. Debido a que el contexto es accesible a través de la [REST API](/features/rest-api) y el [MCP server](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** - Incorpora la voz de tu organización en un agente de contenido que redacta publicaciones de redes sociales, campañas de correo electrónico o textos para páginas de aterrizaje. La terminología mantiene los términos de marca consistentes y la configuración de voz garantiza que el tono coincida con tu marca.

**Documentación** - Alimenta la memoria de idiomas en una tubería de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas de terminología evitan desviaciones entre la documentación, los artículos de ayuda y los textos dentro del producto.

**Revisión de código** - Construye un agente que revise el texto de las solicitudes de extracción (mensajes de error, etiquetas de la interfaz, texto de incorporación) contra tu voz y terminología. Marca las inconsistencias antes de que lancen.

**Agentes personalizados** - Cualquier cliente compatible con MCP puede leer y escribir la memoria de idiomas. Pide a tu asistente de codificación que actualice la terminología con el nuevo nombre del producto o que establezca el tono de voz profesional para la localidad en alemán y traduce tu intención en la llamada de API correcta.

## Refinamiento progresivo

La memoria de idiomas mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se alimenta en la próxima versión de tu voz o terminología. Con el tiempo, la brecha entre el primer borrador y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar el contexto, generar de nuevo. Los agentes no solo siguen las instrucciones. Trabajan con contexto que mejora cada ciclo.