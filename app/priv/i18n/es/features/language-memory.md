%{
  title: "Memoria de idioma",
  summary:
    "Una capa de contexto con versiones que capta la voz, la terminología y el estilo de su organización. La memoria de idioma guía cada flujo de trabajo de agentes y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado y auditable",
      description:
        "Cada cambio en su voz o terminología crea una nueva versión inmutable. Puede revisar el historial, comparar iteraciones y revertir si algo se desvía.",
      icon: "git-branch"
    },
    %{
      title: "Más allá de la localización",
      description:
        "La memoria de idioma no es solo para localización. Úsela para generar textos de marketing, redactar documentación, revisar pull requests o crear publicaciones en redes sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria de idioma mediante la API REST o el servidor MCP. Integre la misma en sus propios pipelines de CI, herramientas de contenido o agentes personalizados para mantener la coherencia en todo lo que escribe.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de lenguaje?

La memoria de lenguaje es el contexto acumulado que indica a los agentes de Glossia cómo se comunica su organización. Está compuesta por dos primitivas centrales que crea y refina con el tiempo:

**Voz** define cómo debe sonar el contenido. Tono, formalidad, público objetivo y directrices de formato libre residen aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para cada localización, para que tu texto en japonés sea más formal mientras tu inglés permanece conversacional.

**Terminología** define el significado de los términos y cómo deben localizarse. Cada entrada incluye una definición y traducciones por localización. Cuando un agente encuentra "workspace" en tu contenido fuente, la terminología le indica si debe localizarlo, transliterarlo o dejarlo sin cambios, y exactamente qué palabra usar en cada idioma de destino.

Juntos, la voz y la terminología forman una capa contextual que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión requerirá tu resultado.

## Versionado inmutable

La memoria del idioma es de solo adición. Cuando actualice su voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambio opcional que explica la evolución.

Esto significa que siempre tiene un registro de auditoría completo. Puede comparar la versión 3 contra la versión 7 para entender cómo cambió su tono a lo largo de un trimestre. Si un cambio reciente introdujo inconsistencias, revierta a una versión anterior y continúe.

El versionado también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, ya que cada cambio es un evento discreto y trazable.

## Resolución basada en la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria del idioma para ese contexto. Comienza con sus configuraciones base de voz y luego aplica cualquier sobrescritura específica de la localización encima. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesita mantener configuraciones separadas por idioma. Defina sus predeterminados una vez, sobrescriba donde sea necesario y deje que el sistema de resolución maneje el resto.

## Úsela en todas partes

La memoria del idioma fue diseñada para la localización, pero es útil en cualquier lugar donde produzca texto. Porque el contexto es accesible a través del [REST API](/features/rest-api) y el [servidor MCP](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Incorpora la voz de tu organización en un agente de contenido que redacte publicaciones en redes sociales, campañas de correo electrónico o textos de páginas de aterrizaje. La terminología mantiene los términos de marca consistentes y las configuraciones de voz aseguran que el tono coincida con tu marca.

**Documentación** -- Alimenta la memoria lingüística en un pipeline de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas de terminología previenen la deriva entre documentos, artículos de ayuda y los textos del producto.

**Revisión de código** -- Construye un agente que revise el contenido de las pull requests (mensajes de error, etiquetas de UI, textos de incorporación) contra tu voz y terminología. Señala inconsistencias antes de su lanzamiento.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria lingüística. Pide a tu asistente de programación que "actualice la terminología con el nuevo nombre del producto" o que "ajuste el tono de voz a profesional para la localización alemana" y traduce tu intención en la llamada de API correcta.

## Refinamiento progresivo

La memoria lingüística mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se retroalimenta en la siguiente versión de tu voz o terminología. Con el tiempo, la brecha entre el primer borrador y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar el contexto, generar de nuevo. Los agentes no solo siguen las instrucciones. Trabajan con un contexto que mejora en cada ciclo.