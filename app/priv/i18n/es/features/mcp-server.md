%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de codificación con Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, glosario, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "CPU",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia mediante texto plano. Los agentes de IA llaman a herramientas MCP para gestionar voces, glosario y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conéctate con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Intégrate el servidor de Glossia en tu flujo de trabajo de agentes existente y empieza a utilizarlo inmediatamente.",
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

El [Model Context Protocol](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas externas y fuentes de datos. En lugar de crear integraciones personalizadas para cada asistente de programación, expones un único servidor MCP y cualquier cliente compatible puede usarlo.

El servidor MCP de Glossia da a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión del glosario, administración de organización y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas alrededor de los recursos con los que trabajas a diario. Consulta la [referencia completa de herramientas](/docs/reference/mcp/tools) para los parámetros y detalles de uso.

**Cuentas y organizaciones** -- Liste sus cuentas, cree y administre organizaciones, invite miembros y controle el acceso. Los agentes pueden configurar estructuras completas de equipo mediante conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajuste el tono, la formalidad, el público objetivo y las sobrescrituras locales sin salir de su editor.

**Gestión de glosario** -- Mantenga la consistencia del glosario en todo su contenido. Agregue, actualice y versione las entradas del glosario para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Listar e inspeccionar proyectos entre organizaciones.

## Cómo funciona

Apunta tu cliente MCP a `https://your-glossia-instance/mcp` y autentícate con un token Bearer de OAuth. La [guía de configuración de MCP](/docs/reference/mcp/overview) recorre todo el flujo de conexión, incluyendo el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [REST API](/features/rest-api), así que cualquier token que funcione para la API funciona para MCP.

A partir de ahí, tu asistente de IA puede invocar cualquiera de las 16 herramientas. Pídele que " cree una organización llamada Acme " o " actualice mi tono de voz a profesional " y el agente traduce tu intención en la llamada a la herramienta adecuada.

## Construido para flujos de trabajo agénticos

MCP no es solo una capa de conveniencia. Es el fundamento para integrar Glossia en pipelines agénticos más grandes. Un asistente de programación puede leer tu base de código, detectar contenido sin localizar, actualizar el glosario con nuevos términos, ajustar las configuraciones de voz para una localización específica y desencadenar una ejecución de traducción, todo en una sola conversación.

Dado que el protocolo está estandarizado, no estás atado a ningún cliente en particular. Alternas entre Claude, Cursor o tu propio agente personalizado sin cambiar una sola línea de configuración.