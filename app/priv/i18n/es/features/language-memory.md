%{
  title: "Memoria de idioma",
  summary:
    "Una capa de contexto versionada que captura la voz, el glosario y el estilo de su organización. La memoria de idioma guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP.",
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
        "La memoria de idioma no es solo para la localización. Utilícela para generar textos de marketing, redactar documentación, revisar pull requests o crear publicaciones sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria de idioma a través de la API REST o el servidor MCP. Intégrelo en sus propios pipelines CI, herramientas de contenido o agentes personalizados para mantener la coherencia en todos los lugares donde escriba.",
      icon: "puzzle"
    }
  ]
}
---

## ¿Qué es la memoria lingüística?

La memoria lingüística es el contexto acumulado que indica a los agentes de Glossia cómo se comunica tu organización. Está compuesta por dos primitivos centrales que creas y perfeccionas con el tiempo:

**Voz** define cómo debe sonar el contenido. Tono, formalidad, audiencia objetivo y directrices de forma libre viven aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para localizaciones individuales, para que tu contenido en japonés sea más formal mientras tu contenido en inglés se mantiene conversacional.

**Glosario** define qué significan los términos y cómo deben localizarse. Cada entrada incluye una definición y traducciones por localización. Cuando un agente encuentra "espacio de trabajo" en tu contenido de origen, el glosario le indica si localizar, transliterar o dejarlo intacto, y exactamente qué palabra usar en cada idioma destino.

En conjunto, voz y glosario forman una capa de contexto a la que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesitará tu salida.

## Versionamiento inmutable

La memoria lingüística es de solo adición. Cuando actualizas tu voz o glosario, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambios opcional que explica las modificaciones.

Esto significa que siempre tienes un rastro de auditoría completo. Puedes comparar la versión 3 contra la versión 7 para entender cómo se ha desplazado tu tono a lo largo de un trimestre. Si un cambio reciente introdujo inconsistencias, retrocede a una versión anterior y sigue avanzando.

El versionamiento también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por los conflictos, porque cada cambio es un evento discreto y trazable.

## Resolución sensible a la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria lingüística para ese contexto. Empezando con tus configuraciones base de voz y luego aplicando cualquier sustitución específica de localización por encima. Lo mismo ocurre con el glosario: solo se incluyen las entradas que tienen un término localizado para la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesitas mantener configuraciones separadas por idioma. Define tus valores por defecto una vez, sustituye donde importa y deja que el sistema de resolución se encargue del resto.

## Úsalo en todas partes

La memoria lingüística fue diseñada para la localización, pero es útil en cualquier lugar donde produzcas texto. Porque el contexto es accesible a través del [REST API](/features/rest-api) y del [MCP server](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Extrae la voz de tu organización hacia un agente de contenido que redacta publicaciones en redes sociales, campañas de correo electrónico o copias de páginas de aterrizaje. El glosario mantiene la coherencia de los términos de marca y las configuraciones de voz aseguran que el tono coincida con tu marca.

**Documentación** -- Canaliza la memoria lingüística hacia un pipeline de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas del glosario previenen la deriva entre documentos, artículos de ayuda y copias dentro del producto.

**Revisión de código** -- Construye un agente que revise la copia de solicitudes de extracción (error messages, etiquetas de UI, texto de incorporación) contra tu voz y glosario. Señala las inconsistencias antes de su lanzamiento.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria lingüística. Pide a tu asistente de programación que "actualice el glosario con el nuevo nombre del producto" o "establezca el tono de voz para el profesional en la localización alemana" y traducirá tu intención a la llamada de API correcta.

## Refinamiento progresivo

La memoria lingüística mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se retroalimenta en la próxima versión de tu voz o glosario. Con el tiempo, la brecha entre el primer borrador y la salida final se estrecha, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar contexto, generar de nuevo. Los agentes no siguen solo las instrucciones. Trabajan con un contexto que mejora en cada ciclo.
