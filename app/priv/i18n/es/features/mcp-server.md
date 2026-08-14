%{
  title: "Servidor MCP",
  summary: "Conecte agentes de IA y asistentes de programación a Glossia mediante el Protocolo de Contexto de Modelo. Gestione voces, terminologia, organizaciones y mucho más usando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Interfaz de lenguaje natural", description: "Interactúe con el motor lingüístico de Glossia mediante texto sencillo. Los agentes de IA usan herramientas MCP para gestionar voces, terminologia y organizaciones sin escribir código.", icon: "message-square-text"},
    %{title: "Compatible con cualquier agente", description: "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Integre el servidor de Glossia en su flujo de trabajo con agentes y empiece a usarlo de inmediato.", icon: "puzzle"},
    %{title: "Seguro de forma predeterminada", description: "Cada solicitud MCP se autentica con tokens de portador OAuth 2.1 y se autoriza mediante ámbitos detallados. Utiliza el mismo modelo de seguridad que la API REST.", icon: "shield-check"}
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA con herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de programación, se expone un único servidor MCP que puede utilizar cualquier cliente compatible.

El servidor MCP de Glossia proporciona a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de la voz, gestión de la terminologia, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP ofrece 16 herramientas organizadas en torno a los recursos con los que trabaja a diario. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para conocer los parámetros y los detalles de uso.

**Cuentas y organizaciones**: enumere sus cuentas, cree y gestione organizaciones, invite a miembros y controle el acceso. Los agentes pueden configurar estructuras completas de equipos mediante una conversación.

**Configuración de la voz**: consulte y actualice los ajustes de la voz que determinan cómo Glossia genera y revisa el contenido. Ajuste el tono, la formalidad, el público objetivo y las configuraciones específicas de cada configuración regional sin salir del editor.

**Gestión de la terminologia**: mantenga la coherencia de la terminologia en todo su contenido. Añada, actualice y cree versiones de las entradas de terminologia para que los agentes utilicen siempre los términos correctos.

**Proyectos**: enumere e inspeccione proyectos de distintas organizaciones.

## Cómo funciona

Configure su cliente MCP para que se conecte a `https://your-glossia-instance/mcp` y autentíquese con un token de portador OAuth. La [guía de configuración de MCP](/docs/reference/mcp/overview) explica el flujo de conexión completo, incluidos el registro dinámico del cliente y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [API REST](/features/rest-api), por lo que cualquier token válido para la API también funciona con MCP.

A partir de ahí, su asistente de IA puede utilizar cualquiera de las 16 herramientas. Pídale «crea una organización llamada Acme» o «actualiza el tono de mi voz a profesional» y el agente convertirá su intención en la llamada de herramienta adecuada.

## Diseñado para flujos de trabajo basados en agentes

MCP no es solo una capa práctica. Es la base para integrar Glossia en flujos de trabajo más amplios basados en agentes. Un asistente de programación puede leer su base de código, detectar contenido sin localizar, actualizar la terminologia con términos nuevos, ajustar la configuración de la voz para una configuración regional concreta y activar una ejecución de localización, todo en una sola conversación.

Como el protocolo está estandarizado, no queda vinculado a un único cliente. Puede cambiar entre Claude, Cursor o su propio agente personalizado sin modificar una sola línea de configuración.