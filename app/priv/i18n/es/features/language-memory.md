%{
  title: "Memoria lingüística",
  summary:
    "Una capa de contexto versionada que captura la voz, terminología y estilo de su organización. La memoria lingüística guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Empezar",
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
        "La memoria lingüística no es solo para localización. Úsela para generar contenido de marketing, redactar documentación, revisar solicitudes de extracción o crear publicaciones en redes sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria lingüística a través de la API REST o servidor MCP. Aliméntelo en sus propios pipelines CI, herramientas de contenido o agentes personalizados para mantener la consistencia en todos los sitios donde escriba.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de idioma?

La memoria de idioma es el contexto acumulado que informa a los agentes de Glossia sobre cómo se comunica tu organización. Está compuesta por dos primitivas clave que tú creas y refinan con el tiempo:

**Voz** Define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices de texto libre residen aquí. Puedes establecer una voz base para tu cuenta y luego sobrescribir campos específicos para cada localización, para que tu contenido en japonés pueda ser más formal mientras tu contenido en inglés se mantenga conversacional.

**Terminología** Define lo que significan los términos y cómo deberían localizarse. Cada entrada incluye una definición y traducciones por localización. Cuando un agente encuentra "espacio de trabajo" en tu contenido de origen, la terminología le indica si debe localizar, transliterar o dejarlo intacto, y exactamente qué palabra utilizar en cada idioma objetivo.

Juntos, la voz y la terminología forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión necesita tu salida.

## Versionamiento inmutable

La memoria de idioma es de solo adición. Cuando actualiza su voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambio opcional explicando qué evolucionó.

Esto significa que siempre dispone de una bitácora completa de auditoría. Puede comparar la versión 3 con la versión 7 para entender cómo cambió su tono durante un trimestre. Si un cambio reciente introdujo inconsistencias, vuelva a una versión anterior y continúe.

El versionado también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, ya que cada cambio es un evento discreto y rastreable.

## Resolución consciente del idioma

Cuando un agente ejecuta un flujo de trabajo para un idioma específico, Glossia resuelve la memoria de idioma para ese contexto. Comienza con su configuración base de voz y luego aplica cualquier sobrescritura específica del idioma encima. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para el idioma objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesita mantener configuraciones separadas por idioma. Defina sus valores predeterminados una vez, sobrescriba donde sea necesario y deje que el sistema de resolución se encargue del resto.

## Úsela en todas partes

La memoria de idioma fue diseñada para la localización, pero es útil en cualquier lugar donde genere texto. Ya que el contexto es accesible a través de la [REST API](/features/rest-api) y el [servidor MCP](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Incorpora la voz de tu organización en un agente de contenido que redacte publicaciones en redes sociales, campañas de correo electrónico o textos para páginas de aterrizaje. La terminología mantiene los términos de marca consistentes y las configuraciones de voz garantizan que el tono coincida con tu marca.

**Documentación** -- Proporciona memoria lingüística a un flujo de documentación para que la escritura técnica siga las mismas reglas de estilo que el resto de tu contenido. Las entradas de terminología evitan la deriva en la documentación, artículos de ayuda y textos del producto.

**Revisión de código** -- Construye un agente que revise el contenido de las solicitudes de extracción (mensajes de error, etiquetas UI, textos de incorporación) contra tu voz y terminología. Señala inconsistencias antes de que se publiquen.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria de lenguaje. Pide a tu asistente de programación que "actualice la terminología con el nuevo nombre del producto" o "configure el tono de voz a profesional para el entorno alemán" y traduce tu intención en la llamada a la API correcta.

## Mejora progresiva

La memoria de lenguaje mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se reintegra en la siguiente versión de tu voz o terminología. Con el tiempo, la brecha entre el primer borrador y la salida final se reduce, y el paso de revisión se vuelve más rápido.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar el contexto, generar de nuevo. Los agentes no solo siguen instrucciones. Trabajan con el contexto que mejora con cada ciclo.