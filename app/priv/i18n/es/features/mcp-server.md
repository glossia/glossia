%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de programación a Glossia a través del Model Context Protocol. Gestiona voces, terminología, organizaciones y más usando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
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
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Integra el servidor de Glossia en tu flujo de trabajo de agentes existente y empieza a usarlo de inmediato.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens portador OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia da acceso directo a los agentes al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organización y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas en torno a los recursos con los que trabajas diariamente. Consulta la [referencia completa de herramientas](/docs/reference/mcp/tools) para detalles de parámetros y uso.

**Cuentas y organizaciones** -- Liste sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar toda la estructura del equipo a través de la conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajuste el tono, la formalidad, el público objetivo y las excepciones por localización sin salir de su editor.

**Gestión de terminología** -- Mantenga la consistencia terminológica en todo su contenido. Agregue, actualice y versione entradas de terminología para que los agentes siempre usen los términos correctos.

**Proyectos** -- Listar e inspeccionar proyectos en todas las organizaciones.

## Cómo funciona

Dirige tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token bearer de OAuth. La [guía de configuración del MCP](/docs/reference/mcp/overview) recorre el flujo completo de conexión, incluyendo el registro dinámico de clientes y PKCE. El [REST API](/features/rest-api), por lo tanto, cualquier token que funcione para la API funciona para MCP.

A partir de ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídele que "crear una organización llamada Acme" o "actualizar mi tono de voz a profesional" y el agente traduce tu intención en la llamada a la herramienta correcta.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es la base para componer Glossia en pipelines agénticos más grandes. Un asistente de codificación puede leer tu base de código, detectar contenido sin localizar, actualizar terminología con nuevos términos, ajustar configuraciones de voz para una localización específica y desencadenar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no estás atado a ningún cliente único. Cambia entre Claude, Cursor o tu agente personalizado sin modificar una sola línea de configuración.