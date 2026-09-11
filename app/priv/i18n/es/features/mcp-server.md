%{
  title: "servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de codificación con Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, terminología, organizaciones y mucho más mediante lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA llaman a las herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Incorpora el servidor de Glossia en tu flujo de trabajo de agentes existente y comienza a utilizarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens de portador OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas externas y fuentes de datos. En lugar de crear integraciones personalizadas para cada asistente de codificación, expones un solo servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia otorga a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas en torno a los recursos con los que trabajas diariamente. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para los parámetros y los detalles de uso.

**Cuentas y organizaciones** -- Consulte sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar estructuras completas de equipos mediante conversación.

**Configuración de voz** -- Consulte y actualice los ajustes de voz que controlan cómo Glossia genera y revisa contenido. Ajuste el tono, la formalidad, la audiencia objetivo y las sobrescritas por localización sin salir de su editor.

**Gestión de terminología** -- Mantenga la coherencia terminológica en todo su contenido. Añada, actualice y versione las entradas de terminología para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Listar y revisar proyectos a través de organizaciones.

## Cómo funciona

Dirija su cliente MCP a `https://your-glossia-instance/mcp` y autenticarse con un token Bearer de OAuth. La [Guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluyendo el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que el [REST API](/features/rest-api), por lo tanto, cualquier token que funcione para la API también funciona para MCP.

Desde ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídesele que "crear una organización llamada Acme" o "actualizar mi tono de voz a profesional" y el agente traduce tu intención a la llamada de herramienta adecuada.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es la base para integrar Glossia en pipelines agéntiques más grandes. Un asistente de programación puede leer tu base de código, detectar contenido no localizado, actualizar la terminología con nuevos términos, ajustar la configuración de voz para un idioma específico e iniciar un proceso de localización, todo en una sola conversación.

Dado que el protocolo es estandarizado, no estás atado a ningún cliente único. Cambia entre Claude, Cursor o tu propio agente personalizado sin modificar una sola línea de configuración.