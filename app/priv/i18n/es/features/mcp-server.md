%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de programación a Glossia a través del Model Context Protocol. Gestiona voces, terminología, organizaciones, y mucho más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA llaman herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conéctate con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Incorpora el servidor de Glossia en tu flujo de trabajo de agentes existente y comienza a usarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens Bearer de OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de contexto de modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA con herramientas y fuentes de datos externas. En lugar de construir integraciones personalizadas para cada asistente de codificación, expones un solo servidor MCP y cualquier cliente compatible puede usarlo.

El servidor MCP de Glossia da a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organización y listado de proyectos.

## Herramientas disponibles

El [referencia completa de herramientas](/docs/reference/mcp/tools) para parámetros y detalles de uso.

**Cuentas y organizaciones** -- Enumere sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar toda la estructura del equipo mediante conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa contenido. Ajuste tono, formalidad, público objetivo y sobrescritas locales sin salir de su editor.

**Gestión de terminología** -- Mantenga la coherencia terminológica en todo su contenido. Agregue, actualice y versione entradas de terminología para que los agentes siempre usen los términos correctos.

**Proyectos** -- Listar e inspeccionar proyectos entre organizaciones.

## Cómo funciona

Apunta tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token de portador OAuth. La [Guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo completo de conexión, incluyendo el registro dinámico del cliente y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [REST API](/features/rest-api), así cualquier token que funcione para la API también funciona para MCP.

Desde allí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídele que "cree una organización llamada Acme" o "actualice el tono de mi voz al profesional" y el agente traduce tu intención en la llamada de herramienta correcta.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de utilidad. Es la base para integrar Glossia en pipelines agénticos más grandes. Un asistente de programación puede leer tu base de código, detectar contenido no localizado, actualizar la terminología con nuevos términos, ajustar la configuración de voz para una localización específica y desencadenar una ejecución de localización, todo en una sola conversación.

Como el protocolo es estandarizado, no estás atado a ningún cliente único. Cambia entre Claude, Cursor o tu propio agente personalizado sin modificar una línea de configuración.