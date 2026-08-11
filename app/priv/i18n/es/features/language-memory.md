%{
  title: "Memoria lingüística",
  summary: "Una capa de contexto versionada que captura la voz, la terminologia y el estilo de su organización. La memoria lingüística guía cada flujo de trabajo de los agentes y se integra con sus propias herramientas mediante la API y MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Versionada y auditable", description: "Cada cambio en su voz o terminologia crea una nueva versión inmutable. Puede revisar el historial, comparar iteraciones y revertir los cambios si se produce alguna desviación.", icon: "git-branch"},
    %{title: "Más allá de la localización", description: "La memoria lingüística no sirve solo para la localización. Úsela para generar textos de marketing, redactar documentación, revisar solicitudes de incorporación de cambios o crear publicaciones para redes sociales, todo con la voz de su organización.", icon: "megaphone"},
    %{title: "Abierta y extensible", description: "Acceda a la memoria lingüística mediante la API REST o el servidor MCP. Intégrela en sus propios procesos de integración continua, herramientas de contenido o agentes personalizados para mantener la coherencia en todo lo que escriba.", icon: "puzzle"}
  ]
}
---
## ¿Qué es la memoria lingüística?

La memoria lingüística es el contexto acumulado que indica a los agentes de Glossia cómo se comunica su organización. Se compone de dos elementos fundamentales que usted crea y perfecciona con el tiempo:

La **voz** define cómo debe sonar el contenido. Aquí se establecen el tono, la formalidad, el público objetivo y las directrices de formato libre. Puede definir una voz base para su cuenta y después modificar campos específicos para cada configuración regional, de modo que el texto en japonés pueda ser más formal mientras que el texto en inglés mantiene un tono conversacional.

La **terminologia** define qué significan los términos y cómo deben localizarse. Cada entrada incluye una definición y traducciones por configuración regional. Cuando un agente encuentra "workspace" en su contenido de origen, la terminologia le indica si debe localizarlo, transliterarlo o dejarlo intacto, además de la palabra exacta que debe utilizar en cada idioma de destino.

En conjunto, la voz y la terminologia forman una capa de contexto que los agentes consultan en cada ejecución. Cuanto más invierta en esta capa, menos revisión necesitará el resultado.

## Versionado inmutable

La memoria lingüística solo permite añadir información. Cuando actualiza su voz o terminologia, Glossia crea una nueva versión en lugar de sobrescribir la anterior. Cada versión registra quién la creó, cuándo lo hizo y, de forma opcional, una nota de cambio que explica su evolución.

Esto significa que siempre dispone de un historial de auditoría completo. Puede comparar la versión 3 con la versión 7 para comprender cómo cambió su tono durante un trimestre. Si un cambio reciente introdujo incoherencias, revierta a una versión anterior y continúe.

El versionado también hace que la colaboración sea más segura. Varios miembros del equipo pueden proponer cambios en la voz sin preocuparse por conflictos, ya que cada cambio es un evento independiente y trazable.

## Resolución según la configuración regional

Cuando un agente ejecuta un flujo de trabajo para una configuración regional específica, Glossia resuelve la memoria lingüística correspondiente a ese contexto. Comienza con la configuración de su voz base y después aplica las modificaciones específicas de la configuración regional. Lo mismo ocurre con la terminologia: solo se incluyen las entradas que tienen un término localizado para la configuración regional de destino.

Este paso de resolución garantiza que los agentes trabajen siempre con el contexto más relevante. No necesita mantener configuraciones independientes para cada idioma. Defina los valores predeterminados una vez, modifíquelos donde sea necesario y deje que el sistema de resolución se ocupe del resto.

## Úsela en todas partes

La memoria lingüística se diseñó para la localización, pero resulta útil en cualquier proceso en el que produzca texto. Como se puede acceder al contexto mediante la [API REST](/features/rest-api) y el [servidor MCP](/features/mcp-server), puede integrarlo en flujos de trabajo que van más allá de la localización:

**Contenido de marketing y redes sociales** -- Incorpore la voz de su organización a un agente de contenido que redacte publicaciones para redes sociales, campañas de correo electrónico o textos para páginas de destino. La terminologia mantiene la coherencia de los términos de marca y la configuración de la voz garantiza que el tono corresponda al de su marca.

**Documentación** -- Incorpore la memoria lingüística a un proceso de documentación para que la redacción técnica siga las mismas reglas de estilo que el resto del contenido. Las entradas de terminologia evitan divergencias entre la documentación, los artículos de ayuda y los textos del producto.

**Revisión de código** -- Cree un agente que revise los textos de las solicitudes de incorporación de cambios, como mensajes de error, etiquetas de la interfaz de usuario y textos de incorporación, conforme a su voz y terminologia. Detecte las incoherencias antes de publicarlas.

**Agentes personalizados** -- Cualquier cliente compatible con MCP puede leer y escribir la memoria lingüística. Pida a su asistente de programación que "actualice la terminologia con el nuevo nombre del producto" o que "establezca un tono profesional para la voz de la configuración regional alemana", y este traducirá su intención en la llamada adecuada a la API.

## Perfeccionamiento progresivo

La memoria lingüística mejora con el uso. Cada vez que una persona revisora corrige el resultado de un agente, esa corrección se incorpora a la siguiente versión de su voz o terminologia. Con el tiempo, se reduce la diferencia entre el primer borrador y el resultado final, y la revisión se agiliza.

Este es el ciclo de retroalimentación central de Glossia: generar, revisar, perfeccionar el contexto y volver a generar. Los agentes no se limitan a seguir instrucciones. Trabajan con un contexto que mejora en cada ciclo.