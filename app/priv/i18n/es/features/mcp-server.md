%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de programación a Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, terminología, organizaciones y más usando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA utilizan herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Coloca el servidor de Glossia en tu flujo de trabajo de agentes existente y empieza a usarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens Bearer OAuth 2.1 y se autoriza contra ámbitos granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Model Context Protocol](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA con herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia da a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas en torno a los recursos con los que trabaja diariamente. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para los parámetros y detalles de uso.

**Cuentas y organizaciones** -- Administra tus cuentas, crea y gestiona organizaciones, invita a miembros y controla el acceso. Los agentes pueden configurar toda la estructura del equipo a través de la conversación.

**Configuración de voz** -- Lee y actualiza los ajustes de voz que controlan cómo Glossia genera y revisa el contenido. Ajusta tono, formalidad, público objetivo y sobrescrituras de localización sin salir de tu editor.

**Gestión de terminología** -- Mantén la coherencia terminológica en todo tu contenido. Añade, actualiza y versiona las entradas de terminología para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Listar e inspeccionar proyectos en varias organizaciones.

## ¿Cómo funciona?

Dirige tu cliente MCP a `https://your-glossia-instance/mcp` y autenticarse con un token de portador OAuth. El [guía de configuración MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluyendo el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que el [REST API](/features/rest-api), así que cualquier token que funcione para la API también funciona para MCP.

A partir de ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídele que "crea una organización llamada Acme" o que "actualice mi tono de voz a profesional" y el agente traduce tu intención a la llamada de herramienta correcta.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es la base para integrar Glossia en tuberías agénticas más grandes. Un asistente de programación puede leer tu código base, detectar contenido sin localizar, actualizar la terminología con nuevos términos, ajustar las configuraciones de voz para un idioma específico y activar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo es estandarizado, no estás atado a ningún cliente en particular. Cambia entre Claude, Cursor o tu propio agente personalizado sin alterar una línea de configuración.