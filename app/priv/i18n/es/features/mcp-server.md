%{
  title: "Servidor MCP",
  summary:
    "Conecta los agentes de IA y asistentes de codificación con Glossia mediante el Protocolo de Contexto de Modelo. Gestiona voces, terminología, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia mediante texto plano. Los agentes de IA invocan herramientas MCP para administrar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Añade el servidor Glossia a tu flujo de trabajo existente y comienza a usarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens Bearer OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de inteligencia artificial a herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de codificación, expones un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia da a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP ofrece 16 herramientas organizadas en torno a los recursos con los que trabajas a diario. Consulta la [referencia completa de herramientas](/docs/reference/mcp/tools) para detalles de parámetros y uso.

**Cuentas y organizaciones** -- Lista tus cuentas, crea y gestiona organizaciones, invita a miembros y controla el acceso. Los agentes pueden configurar toda la estructura del equipo a través de la conversación.

**Configuración de voz** -- Lee y actualiza los ajustes de voz que controlan cómo Glossia genera y revisa contenido. Ajusta el tono, formalidad, público objetivo y sobrescrituras por localización sin salir de tu editor.

**Gestión de terminología** -- Mantén la coherencia terminológica en todo tu contenido. Añade, actualiza y versiona las entradas terminológicas para que los agentes siempre usen los términos correctos.

**Proyectos** -- Listar y revisar proyectos entre organizaciones.

## Cómo funciona

Apunte su cliente MCP a `https://your-glossia-instance/mcp` y autentíquese con un token de portador OAuth. El [guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluyendo el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que el [REST API](/features/rest-api), y cualquier token que funcione para la API también funciona para MCP.

Desde ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídele que "crear una organización llamada Acme" o que "actualizar mi tono de voz a profesional" y el agente traduce tu intención a la llamada de herramienta correcta.

## Diseñado para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es la base para integrar Glossia en pipelines agénticos más grandes. Un asistente de programación puede leer tu base de código, detectar contenido sin localizar, actualizar la terminología con nuevos términos, ajustar la configuración de voz para un idioma específico y desencadenar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no estás atado a ningún cliente único. Cambia entre Claude, Cursor o tu propio agente personalizado sin modificar una línea de configuración.