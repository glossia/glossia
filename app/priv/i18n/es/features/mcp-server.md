%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de código a Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, glosario, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia mediante texto plano. Los agentes de IA invocan herramientas MCP para gestionar voces, glosario y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Coloca el servidor de Glossia en tu flujo de trabajo agéntico existente y empieza a usarlo de inmediato.",
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

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas externas y fuentes de datos. En lugar de crear integraciones personalizadas para cada asistente de programación, expone un único servidor MCP y cualquier cliente compatible puede usarlo.

El servidor MCP de Glossia da a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión del glosario, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas alrededor de los recursos con los que trabajas a diario. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para los detalles de parámetros y uso.

**Cuentas y organizaciones** -- Enumere sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar toda la estructura del equipo mediante conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajuste el tono, formalidad, público objetivo y las sobrescrituras por localización sin salir de tu editor.

**Gestión del glosario** -- Mantenga la coherencia del glosario en todo su contenido. Añada, actualice y versiona las entradas del glosario para que los agentes siempre usen los términos correctos.

**Proyectos** -- Enumere y revise proyectos en todas las organizaciones.

## Cómo funciona

Dirija su cliente MCP a `https://your-glossia-instance/mcp` y autentíquese con un token de portador OAuth. La [Guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluido el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [API REST](/features/rest-api), por lo que cualquier token que funcione para la API también funciona para MCP.

A partir de ahí, su asistente de IA puede llamar a cualquiera de las 16 herramientas. Pregúntele para "crear una organización llamada Acme" o "actualizar el tono de voz a profesional" y el agente traduzca su intención en la llamada de la herramienta adecuada.

## Diseñado para flujos de trabajo de agentes

MCP no es solo una capa de comodidad. Es la base para componer Glossia en pipelines de agentes más grandes. Un asistente de programación puede leer su base de código, detectar contenido no localizado, actualizar el glosario con nuevos términos, ajustar la configuración de voz para una localización específica y desencadenar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no está limitado a ningún cliente único. Cambie entre Claude, Cursor o su propio agente personalizado sin modificar una sola línea de configuración.
