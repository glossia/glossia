%{
  title: "Memoria lingüística",
  summary:
    "Una capa de contexto versionada que captura la voz, el glosario y el estilo de su organización. La memoria lingüística guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado y auditable",
      description:
        "Cada cambio a su voz o glosario crea una nueva versión inmutable. Puede revisar el historial, comparar iteraciones y revertir si algo se desvía.",
      icon: "git-branch"
    },
    %{
      title: "Más allá de la localización",
      description:
        "La memoria lingüística no es solo para localización. Úsela para generar textos de marketing, redactar documentación, revisar pull requests o crear publicaciones en redes sociales, todo con la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria lingüística a través de la API REST o del servidor MCP. Alimentela en sus propios pipelines de CI, herramientas de contenido o agentes personalizados para mantener la consistencia en todo lo que escriba.",
      icon: "puzzle"
    }
  ]
}
---

## ¿Qué es la memoria de idioma?

La memoria de idioma es el contexto acumulado que indica a los agentes de Glossia cómo se comunica su organización. Está compuesta por dos primitivas fundamentales que usted crea y refina con el tiempo:

**Voz** define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices libres residen aquí. Puedes configurar una voz base para tu cuenta y luego sobrescribir campos específicos para cada localización, de modo que tu texto en japonés pueda ser más formal mientras que el inglés mantenga un tono conversacional.

**Glosario** define el significado de los términos y cómo deben localizarse. Cada entrada contiene una definición y traducciones por localización. Cuando un agente encuentra "espacio de trabajo" en tu contenido fuente, el glosario indica si debe traducirse, transliterarse o dejarse como está, y exactamente qué palabra utilizar en cada idioma de destino.

Juntos, la voz y el glosario forman una capa de contexto que consultan los agentes en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesitará tu resultado.

## Versionado inmutable

La memoria de idioma es solo para añadir. Cuando actualices tu voz o glosario, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambios opcional que explica lo que evolucionó.

Esto significa que siempre cuentas con un registro de auditoría completo. Puedes comparar la versión 3 con la versión 7 para entender cómo cayó tu tono en un trimestre. Si un cambio reciente introdujo inconsistencias, vuelve a una versión anterior y continúa.

El versionado también hace más segura la colaboración. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, ya que cada cambio es un evento discreto y rastreable.

## Resolución sensible a la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria de idioma para ese contexto. Comienza con la configuración de voz base y luego aplica las sobrescrituras específicas de localización por encima. Lo mismo ocurre con el glosario: solo se incluyen las entradas que tienen un término traducido en la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesitas mantener configuraciones separadas por idioma. Define tus valores por defecto una vez, sobrescribe donde es necesario y deja que el sistema de resolución lo maneje.

## Úsalo en todas partes

La memoria de idioma fue diseñada para la localización, pero es útil en cualquier lugar donde produces texto. Dado que el contexto es accesible a través de la [API REST](/features/rest-api) y el [servidor MCP](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Contenido de marketing y redes sociales** -- Incorpora la voz de tu organización en un agente de contenido que redacta publicaciones de redes sociales, campañas de correo electrónico o textos para páginas de aterrizaje. El glosario mantiene los términos de marca consistentes y la configuración de voz asegura que el tono coincida con tu marca.

**Documentación** -- Ingresa la memoria de idioma en un pipeline de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas del glosario evitan la deriva en los documentos, artículos de ayuda y textos de producto.

**Revisión de código** -- Crea un agente que revise el texto de las solicitudes de extracción (mensajes de error, etiquetas de UI, textos de incorporación) respecto a tu voz y glosario. Marca las inconsistencias antes de su lanzamiento.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria de idioma. Pide a tu asistente de codificación que "actualice el glosario con el nuevo nombre del producto" o "establezca el tono de voz como profesional para la localización alemana" y traduce tu intención en la llamada API correcta.

## Refinamiento progresivo

La memoria de idioma mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se retroalimenta en la próxima versión de tu voz o glosario. Con el tiempo, la brecha entre el primer borrador y la salida final se estrecha, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el núcleo de Glossia: generar, revisar, refinar el contexto, generar de nuevo. Los agentes no solo siguen instrucciones. Trabajan con un contexto que mejora en cada ciclo.
