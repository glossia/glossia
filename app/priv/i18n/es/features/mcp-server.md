%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de codificación a Glossia a través del Protocolo de Contexto de Modelo. Gestiona voces, terminología, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia mediante texto plano. Los agentes de IA utilizan herramientas MCP para gestionar voces, terminología y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Integra el servidor de Glossia en tu flujo de trabajo de agentes existente y empieza a usarlo de inmediatamente.",
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

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA con herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia otorga a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de terminología, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas en torno a los recursos con los que trabaja diariamente. Vea la [referencia completa de herramientas](/docs/reference/mcp/tools) para parámetros y detalles de uso.

**Cuentas y organizaciones** -- Liste sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar estructuras de equipo completas mediante la conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajuste el tono, formalidad, público objetivo y sobrescrituras por idioma sin salir de su editor.

**Administración de terminología** -- Mantenga la consistencia terminológica en todo su contenido. Agregue, actualice y versione las entradas de terminología para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Listar y revisar proyectos entre organizaciones.

## Cómo funciona

Dirige tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token Bearer de OAuth. La [guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo completo de conexión, incluyendo el registro dinámico del cliente y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que el [REST API](/features/rest-api), así que cualquier token que funcione para la API funciona para MCP.

Desde ahí, su asistente de IA puede invocar cualquiera de las 16 herramientas. Pídale que " Cree una organización llamada Acme" o " actualice el tono de mi voz a profesional" y el agente traduce su intención en la llamada a la herramienta correcta.

## Construido para flujos de trabajo de agentes

MCP no es solo una capa de conveniencia. Es el fundamento para componer Glossia en tuberías de agentes más grandes. Un asistente de programación puede leer su base de código, detectar contenido no localizado, actualizar la terminología con nuevos términos, ajustar las configuraciones de voz para una localización específica e iniciar una ejecución de localización, todo en una conversación única.

Dado que el protocolo está estandarizado, no está limitado a ningún cliente único. Cambie entre Claude, Cursor o su propio agente personalizado sin alterar una sola línea de configuración.