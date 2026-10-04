%{
  title: "Memoria lingüística",
  summary:
    "Una capa de contexto versionada que captura la voz, el glosario y el estilo de su organización. La memoria lingüística guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Empezar",
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
        "La memoria lingüística no es solo para la localización. Úsela para generar contenido de marketing, redactar documentación, revisar pull requests o crear publicaciones de redes sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria lingüística a través de la API REST o el servidor MCP. Incorpórela a sus propios pipelines de CI, herramientas de contenido o agentes personalizados para mantener la consistencia en todas partes donde escriba.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de lenguaje?

La memoria de lenguaje es el contexto acumulado que indica a los agentes de Glossia cómo se comunica tu organización. Está compuesta por dos primitivas básicas que creas y refinas con el tiempo:

**Voz** define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices de redacción libre residen todos aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para cada localización, de manera que tu texto en japonés sea más formal mientras tu inglés permanezca conversacional.

**Glosario** define el significado de los términos y cómo deben localizarse. Cada entrada incluye una definición y traducciones por localización. Cuando un agente encuentra "workspace" en tu contenido de origen, el glosario indica si debe localizar, trasliterar o dejarlo intacto, y exactamente qué palabra utilizar en cada idioma objetivo.

Juntos, voz y glosario forman una capa de contexto que consultan los agentes en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesitará tu salida.

## Versionado inmutable

La memoria del lenguaje es de solo apéndice. Cuando actualice su voz o glosario, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambios opcional que explica qué evolucionó.

Esto significa que siempre tiene un registro de auditoría completo. Puede comparar la versión 3 contra la versión 7 para entender cómo cambió su tono durante un trimestre. Si un cambio reciente introdujo inconsistencias, restablezca a una versión anterior y continúe.

La versionización también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios en la voz sin preocuparse por conflictos, porque cada cambio es un evento discreto y trazable.

## Resolución sensible a la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria del lenguaje para ese contexto. Comienza con sus configuraciones de voz base y luego aplica cualquier sobrescripción específica de la localización por encima. Lo mismo ocurre con el glosario: solo se incluyen entradas que tienen un término localizado para la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesita mantener configuraciones separadas por idioma. Defina sus valores por defecto una vez, sobrescriba donde sea necesario y deje que el sistema de resolución se encargue del resto.

## Úsalo en todas partes

La memoria del lenguaje fue diseñada para la localización, pero es útil en cualquier lugar donde produzca texto. Debido a que el contexto es accesible a través del [API REST](/features/rest-api) y el [servidor MCP](/features/mcp-server), así puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Incorpora la voz de tu organización en un agente de contenido que redacta publicaciones de redes sociales, campañas de correo electrónico o textos para páginas de aterrizaje. Glosario mantiene los términos de marca consistentes y las configuraciones de voz aseguran que el tono coincida con tu marca.

**Documentación** -- Alimenta la memoria del lenguaje en un flujo de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas de Glosario previenen la deriva en documentos, artículos de ayuda y el contenido del producto.

**Revisión de código** -- Crea un agente que revise el contenido de las solicitudes de extracción (mensajes de error, etiquetas de interfaz, texto de incorporación) contra tu voz y glosario. Marca las inconsistencias antes de que sean publicadas.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria del idioma. Pídele a tu asistente de programación que "actualice el glosario con el nuevo nombre del producto" o que "establezca el tono de voz a profesional para la localización alemana" y traduce tu intención en la llamada a la API adecuada.

## Refinamiento progresivo

\-- La memoria del idioma mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se retroalimenta en la siguiente versión de tu voz o glosario. Con el tiempo, la brecha entre el borrador inicial y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: genera, revisa, refina contexto, genera de nuevo. Los agentes no solo siguen instrucciones. Trabajan con contexto que mejora en cada ciclo.