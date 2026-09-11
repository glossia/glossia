%{
  title: "Memoria de idioma",
  summary:
    "Una capa de contexto versionada que captura la voz, terminología y estilo de su organización. La memoria de idioma guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado y auditado",
      description:
        "Cada cambio en su voz o terminología crea una nueva versión inmutable. Puede revisar el historial, comparar iteraciones y revertir si algo se desvía.",
      icon: "git-branch"
    },
    %{
      title: "Más allá de la localización",
      description:
        "La memoria de idioma no es solo para la localización. Úsela para generar material de marketing, redactar documentación, revisar pull requests o crear publicaciones en redes sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria de idioma a través de la REST API o servidor MCP. Incorpórelo en sus propios flujos de CI, herramientas de contenido o agentes personalizados para mantener la consistencia en todo lo que escribe.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de idioma?

La memoria de idioma es el contexto acumulado que indica a los agentes de Glossia cómo se comunica su organización. Está compuesta por dos primitivas centrales que usted crea y refina con el tiempo:

**Voz** Define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices de formato libre residen aquí. Puede establecer una voz base para su cuenta y luego sobrescribir campos específicos para locales individuales, para que su contenido en japonés sea más formal mientras el inglés permanece conversacional.

**Terminología** Define qué significan los términos y cómo deben localizarse. Cada entrada incluye una definición y traducciones por localización. Cuando un agente encuentra "workspace" en el contenido fuente, la terminología indica si debe localizar, transliterar o dejarlo intacto, y exactamente qué palabra usar en cada idioma objetivo.

Juntas, la voz y la terminología forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más invierta en esta capa, menos revisión necesita su resultado.

## Versionado inmutable

La memoria de lenguaje es de adición exclusiva. Cuando actualizas tu voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la antigua. Cada versión registra quién la creó, cuándo y una nota de cambios opcional que explica qué ha evolucionado.

Esto significa que siempre tienes un rastro completo de auditoría. Puedes comparar la versión 3 contra la versión 7 para entender cómo cambió tu tono a lo largo del trimestre. Si un cambio reciente introdujo inconsistencias, vuelve a una versión anterior y continuas.

El versionado también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, ya que cada cambio es un evento discreto y rastreable.

## Resolución contextual

Cuando un agente ejecuta un flujo de trabajo para un idioma específico, Glossia resuelve la memoria de lenguaje para ese contexto. Comienza con tus configuraciones base de voz y luego aplica cualquier sobrescritura específica del idioma. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para el idioma objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesitas mantener configuraciones separadas por idioma. Define tus valores por defecto una vez, sobrescribe donde importa y deja que el sistema de resolución gestione lo demás.

## Úsalo en todas partes.

La memoria de lenguaje se diseñó para la localización, pero es útil en cualquier lugar donde produzcas texto. Debido a que el contexto es accesible a través del [REST API](/features/rest-api) y el [servidor MCP](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Incorpora la voz de tu organización en un agente de contenido que redacte publicaciones en redes sociales, campañas de correo electrónico o textos para páginas de destino. La Terminología mantiene los términos de marca consistentes y la configuración de voz garantiza que el tono coincida con tu marca.

**Documentación** -- Alimenta la memoria lingüística en un flujo de documentación para que los textos técnicos sigan las mismas reglas de estilo que el resto de tu contenido. Las entradas de Terminología evitan la deriva en documentos, artículos de ayuda y el contenido en el producto.

**Revisión de código** -- Crea un agente que revise el contenido de las solicitudes de extracción (mensajes de error, etiquetas de interfaz de usuario, texto de incorporación) contra tu voz y terminología. Señala las inconsistencias antes de lanzarlas.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria de lenguaje. Pide a tu asistente de codificación que "actualice la terminología con el nuevo nombre del producto" o "establezca el tono de voz profesional para la localización alemana" y traduzca tu intención en la llamada API correcta.

## Refinamiento progresivo

La memoria de lenguaje mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se retroalimenta en la siguiente versión de tu voz o terminología. Con el tiempo, la brecha entre el primer borrador y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar contexto, generar de nuevo. Los agentes no solo siguen las instrucciones. Trabajan con un contexto que mejora con cada ciclo.