%{
  title: "Memoria del lenguaje",
  summary:
    "Una capa de contexto con control de versiones que captura la voz, la terminología y el estilo de su organización. La memoria del lenguaje guía cada flujo de trabajo de agente y se extiende a sus propias herramientas a través de la API y MCP. ",
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
        "La memoria del lenguaje no es solo para la localización. Úsela para generar texto de marketing, redactar documentación, revisar solicitudes de integración o crear publicaciones en redes sociales, todo en la voz de su organización.",
      icon: "megaphone"
    },
    %{
      title: "Abierto y extensible",
      description:
        "Acceda a la memoria del lenguaje a través de la API REST o del servidor MCP. Intégrala en sus propios pipelines de CI, herramientas de contenido o agentes personalizados para mantener la coherencia en todo lo que escriba.",
      icon: "puzzle"
    }
  ]
}
---
## ¿Qué es la memoria de lenguaje?

La memoria de lenguaje es el contexto acumulado que le indica a los agentes de Glossia cómo se comunica tu organización. Está compuesta por dos primitivas fundamentales que creas y refinas con el tiempo:

**Voz** define cómo debe sonar el contenido. El tono, la formalidad, el público objetivo y las directrices libres residen aquí. Puedes establecer una voz base para tu cuenta y luego sobreescribir campos específicos para locales individuales, de modo que tu copia japonesa sea más formal mientras tu inglés se mantenga conversacional.

**Terminología** define qué términos significan y cómo deben localizarse. Cada entrada lleva una definición y traducciones por local. Cuando un agente encuentra "workspace" en tu contenido fuente, la terminología le indica si debe localizarlo, transliterarlo o dejarlo sin tocar, y exactamente qué palabra usar en cada idioma objetivo.

Juntos, la voz y la terminología forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más inviertas en esta capa, menos revisión requiere tu resultado.

## Versionado inmutable

La memoria de idioma es de solo escritura. Cuando actualiza su voz o terminología, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo y una nota de cambio opcional que explica qué evolucionó.

Esto significa que siempre tendrá un registro de auditoría completo. Puede comparar la versión 3 contra la versión 7 para comprender cómo cambió su tono durante un trimestre. Si un cambio reciente introdujo inconsistencias, revierta a una versión anterior y continúe.

El versionado también hace la colaboración más segura. Varios miembros del equipo pueden proponer cambios de voz sin preocuparse por conflictos, porque cada cambio es un evento discreto y trazable.

## Resolución consciente de la localización

Cuando un agente ejecuta un flujo de trabajo para una localización específica, Glossia resuelve la memoria de idioma para ese contexto. Comienza con la configuración de voz base y luego aplica cualquier sobrescritura específica de la localización sobre ella. Lo mismo ocurre con la terminología: solo se incluyen las entradas que tienen un término localizado para la localización objetivo.

Este paso de resolución significa que los agentes siempre trabajan con el contexto más relevante. No necesita mantener configuraciones separadas por idioma. Defina sus valores predeterminados una vez, sobrescriba donde importa y deje que el sistema de resolución gestione el resto.

## Utilícela en todas partes

La memoria de idioma fue diseñada para la localización, pero es útil en cualquier lugar donde produzca texto. Porque el contexto es accesible a través del [API REST](/features/rest-api) y el [servidor MCP](/features/mcp-server), puedes integrarlo en flujos de trabajo más allá de la localización:

**Marketing y contenido social** -- Incorpore la voz de su organización en un agente de contenido que redacte publicaciones para redes sociales, campañas de correo electrónico o textos de aterrizaje. Terminología mantiene los términos de marca consistentes y la configuración de voz garantiza que el tono coincida con su marca.

**Documentación** -- Alimente la memoria lingüística en un flujo de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto de su contenido. Las entradas de terminología evitan la deriva en documentos, artículos de ayuda y el contenido del producto.

**Revisión de código** -- Crea un agente que revise el contenido de las solicitudes pull (mensajes de error, etiquetas de la interfaz de usuario, texto de incorporación) contra tu voz y terminología. Marca las inconsistencias antes de que se publiquen.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir memoria del lenguaje. Pide a tu asistente de código que "actualizar la terminología con el nuevo nombre del producto" o "establecer el tono de voz a profesional para la localización alemana" y traduce tu intención en la llamada de API correcta.

## Refinamiento progresivo

La memoria del lenguaje mejora con el uso. Cada vez que un revisor corrige la salida de un agente, esa corrección se incorpora en la siguiente versión de tu voz o terminología. Con el tiempo, la brecha entre el borrador inicial y el resultado final se reduce, y la etapa de revisión se vuelve más rápida.

Este es el bucle de retroalimentación en el corazón de Glossia: generar, revisar, refinar contexto, generar de nuevo. Los agentes no solo siguen instrucciones. Trabajan con contexto que mejora en cada ciclo.