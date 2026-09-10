%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de codificación con Glossia a través del Model Context Protocol. Gestiona voces, terminología, organizaciones y más usando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA invocan herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Integra el servidor de Glossia en tu flujo de trabajo de agentes existente y empieza a usarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens portadores OAuth 2.1 y se autoriza mediante alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Model Context Protocol](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia brinda a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración organizativa y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas alrededor de los recursos con los que trabaja diariamente. Vea el [referencia completa de herramientas](/docs/reference/mcp/tools) para detalles de parámetros y uso.

**Cuentas y organizaciones** -- Lista tus cuentas, crea y administra organizaciones, invita miembros y controla el acceso. Los agentes pueden configurar estructuras completas de equipo a través de la conversación.

**Configuración de voz** -- Consulta y actualiza la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajusta el tono, la formalidad, el público objetivo y las excepciones por localización sin salir de tu editor.

**Gestión de terminología** -- Mantén la coherencia terminológica en todo tu contenido. Añade, actualiza y versiona las entradas de terminología para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Listar e inspeccionar proyectos en distintas organizaciones.

## Cómo funciona

Dirige tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token de portador OAuth. La [guía de configuración MCP](/docs/reference/mcp/overview) describe el flujo completo de conexión, incluyendo el registro dinámico del cliente y PKCE. El [REST API](/features/rest-api), así que cualquier token que funcione para la API también funciona para MCP.

A partir de ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídelo para "crear una organización llamada Acme" o "actualizar mi tono de voz a profesional" y el agente traduce tu intención en la llamada de herramienta correcta.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es el fundamento para integrar Glossia en tuberías agénticas más grandes. Un asistente de programación puede leer tu base de código, detectar contenido no localizado, actualizar terminología con nuevos términos, ajustar la configuración de voz para una configuración de idioma específica y activar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no estás limitado a ningún cliente único. Cambia entre Claude, Cursor o tu propio agente personalizado sin alterar una línea de configuración.