%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de codificación a Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, terminología, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia mediante texto plano. Los agentes de IA invocan herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Integra el servidor de Glossia en tu flujo de trabajo existente y comienza a usarlo de inmediato.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens OAuth 2.1 de portador y se autoriza mediante alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---
## ¿Qué es MCP?

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas y fuentes de datos externas. En lugar de desarrollar integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede usarlo.

El servidor MCP de Glossia otorga a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas en torno a los recursos con los que trabajas a diario. Consulta la [referencia completa de herramientas](/docs/reference/mcp/tools) para detalles de parámetros y uso.

**Cuentas y organizaciones** -- Lista tus cuentas, crea y gestiona organizaciones, invita miembros y controla el acceso. Los agentes pueden configurar estructuras completas de equipo a través de la conversación.

**Configuración de voz** -- Lee y actualiza los ajustes de voz que controlan cómo Glossia genera y revise el contenido. Ajusta tono, formalidad, audiencia objetivo y ajustes por región sin salir de tu editor.

**Gestión de terminología** -- Mantén la coherencia de terminología en todo tu contenido. Añade, actualiza y versiona las entradas de terminología para que los agentes siempre usen los términos correctos.

**Proyectos** -- Lista e inspecciona proyectos en todas las organizaciones.

## Cómo funciona

Dirige tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token OAuth bearer. La [guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluido el registro de cliente dinámico y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [API REST](/features/rest-api), por lo que cualquier token que funcione para la API también funciona para MCP.

Desde allí, tu asistente de IA puede llamar a cualquiera de las 16 herramientas. Pídele que cree una organización llamada Acme o que actualice el tono de voz a profesional y el agente traduce tu intención en la llamada a la herramienta correcta.

## Diseñado para flujos de trabajo de agentes

MCP no es solo una capa de conveniencia. Es la base para integrar Glossia en pipelines de agentes más grandes. Un asistente de código puede leer tu base de código, detectar contenido no localizado, actualizar la terminología con nuevos términos, ajustar la configuración de voz para una región específica y desencadenar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no te limitas a un solo cliente. Cambia entre Claude, Cursor o tu propio agente personalizado sin cambiar una sola línea de configuración.