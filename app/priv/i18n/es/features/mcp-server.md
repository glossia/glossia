%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de programación a Glossia a través del Protocolo de Contexto de Modelo. Gestiona voces, glosario, organizaciones y más mediante lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA llaman a herramientas MCP para gestionar voces, glosario y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Añade el servidor de Glossia a tu flujo de trabajo agéntico existente y empieza a usarlo de inmediato.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens portadores OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que la API REST.",
      icon: "shield-check"
    }
  ]
}
---

## ¿Qué es MCP?

El [Protocolo de contexto del modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas y fuentes de datos externas. En lugar de construir integraciones personalizadas para cada asistente de codificación, expone un único servidor MCP y cualquier cliente compatible puede utilizarlo.

El servidor MCP de Glossia otorga a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de glosario, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas alrededor de los recursos con los que trabajas diariamente. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para obtener detalles de parámetros y uso.

**Cuentas y organizaciones** -- Liste sus cuentas, cree y administre organizaciones, invite a miembros y controle el acceso. Los agentes pueden establecer toda la estructura del equipo mediante la conversación.

**Configuración de voz** -- Lea y actualice la configuración de voz que controla cómo Glossia genera y revisa el contenido. Ajuste el tono, el formalismo, el público objetivo y las sobreescripciones por idioma sin salir de su editor.

**Gestión de glosario** -- Mantenga la consistencia del glosario en todo su contenido. Agregue, actualice y versione entradas del glosario para que los agentes siempre utilicen los términos correctos.

**Proyectos** -- Liste e inspeccione proyectos a través de organizaciones.

## Cómo funciona

Dirija su cliente MCP a `https://your-glossia-instance/mcp` y autentíquese con un token de portador OAuth. La [guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo completo de conexión, incluido el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que el [REST API](/features/rest-api), por lo que cualquier token que funcione para la API funciona para MCP.

A partir de ahí, su asistente de IA puede llamar a cualquiera de las 16 herramientas. Pídale que " Cree una organización llamada Acme " o " Actualice el tono de mi voz a profesional " y el agente traducirá su intención a la llamada de herramienta correcta.

## Diseñado para flujos de trabajo de agentes

MCP no es solo una capa de comodidad. Es la base para integrar Glossia en tuberías de agentes más grandes. Un asistente de codificación puede leer su base de código, detectar contenido sin localizar, actualizar el glosario con nuevos términos, ajustar la configuración de voz para un idioma específico y desencadenar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está estandarizado, no está atado a ningún único cliente. Cambie entre Claude, Cursor o su propio agente personalizado sin cambiar una línea de configuración.
