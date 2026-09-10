%{
  title: "Memoria de idioma",
  summary:
    "Una capa de contexto versionada que captura la voz, terminología y estilo de tu organización. Memoria de idioma guía cada flujo de trabajo de agente y se extiende a tus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado y auditable",
      description:
        "Cada cambio en tu voz o terminología crea una nueva versión inmutable. Puedes revisar el historial, comparar iteraciones y revertir cambios si algo se desvía.",
      icon: "git-branch"
    },
    %{
      title: "Más allá de la localización",
      description:
        "Memoria de idioma no es solo para localización. Úsala para generar textos de marketing, redactar documentación, revisar solicitudes de pull requests, o redactar publicaciones en redes sociales, todo en la voz de tu organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Accede a la memoria de idioma a través de la API REST o el servidor MCP. Conecta en tus propios pipelines CI, herramientas de contenido o agentes personalizados para mantener la consistencia en todo lo que escribes.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria lingüística?

La memoria lingüística es el contexto acumulado que indica a los agentes de Glossia cómo se comunica tu organización. Se compone de dos primitivas clave que creas y refinas con el tiempo:

**Voz** define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices de formato libre viven aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para cada localización, de modo que tu copia en japonés pueda ser más formal mientras tu contenido en inglés se mantenga conversacional.

**Terminología** define qué significan los términos y cómo deben localizarse. Cada entrada lleva una definición y traducciones por localización. Cuando un agente encuentra \\"workspace\\" en tu contenido fuente, la terminología le indica si debe localizar, transliterar o dejarlo sin cambios, y exactamente qué palabra usar en cada idioma de destino.

Juntos, la voz y la terminología forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesita tu salida.

## Versionado inmutable

La memoria de lenguaje es solo de adición. Cuando actualices tu voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambio opcional que explica qué evolucionó.

Esto significa que siempre cuentas con un historial de auditoría completo. Puedes comparar la versión 3 frente a la versión 7 para entender cómo tu tono cambió en el trimestre. Si un cambio reciente introdujo inconsistencias, vuelve a una versión anterior y continúa.

El versionado también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, ya que cada cambio es un evento discreto y rastreable.

## Resolución sensible a la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria de lenguaje para ese contexto. Comienza con tus configuraciones base de voz y luego aplica cualquier sobrescrita específica de localización. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesitas mantener configuraciones separadas por idioma. Define tus valores predeterminados una vez, sobrescribe donde sea necesario y deja que el sistema de resolución maneje el resto.

## Úsalo en todas partes

La memoria de lenguaje fue diseñada para la localización, pero es útil dondequiera que produzcas texto. Ya que el contexto es accesible a través del [REST API](/features/rest-api) y el [MCP server](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Integra la voz de tu organización en un agente de contenido que redacte publicaciones de redes sociales, campañas de correo electrónico o los textos de las páginas de aterrizaje. Terminología mantiene los términos de marca consistentes y la configuración de voz asegura que el tono coincida con tu marca.

**Documentación** -- Integra la memoria lingüística en un pipeline de documentación para que la escritura técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas de Terminología evitan la deriva en la documentación, artículos de ayuda y los textos del producto.

**Revisión de código** -- Crea un agente que revise el contenido de las solicitudes de extracción (mensajes de error, etiquetas de la interfaz de usuario, texto de incorporación) según tu voz y terminología. Señala las inconsistencias antes de que se lancen.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir memoria lingüística. Pide a tu asistente de programación que "actualice la terminología con el nuevo nombre del producto" o que "configure el tono de voz en profesional para la localización en alemán" y traduce tu intención en la llamada a la API correcta.

## Refinamiento progresivo

\-- La memoria lingüística mejora con el uso. Cada vez que un revisor corrige la salida de un agente, dicha corrección retroalimenta la siguiente versión de tu voz o terminología. Con el tiempo, la brecha entre el primer borrador y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar el contexto, generar de nuevo. Los agentes no solo siguen instrucciones. Trabajan con un contexto que mejora en cada ciclo.