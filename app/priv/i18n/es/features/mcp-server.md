%{
  title: "Servidor MCP",
  summary:
    "Conecta agentes de IA y asistentes de programación a Glossia a través del Protocolo de Contexto del Modelo. Gestiona voces, glosario, organizaciones y más utilizando lenguaje natural desde cualquier cliente compatible con MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interfaz de lenguaje natural",
      description:
        "Interactúa con el motor lingüístico de Glossia a través de texto plano. Los agentes de IA utilizan herramientas MCP para gestionar voces, glosario y organizaciones sin escribir código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecta con cualquier agente",
      description:
        "Funciona con Claude, Cursor, Windsurf y cualquier cliente compatible con MCP. Incorpora el servidor Glossia en tu flujo de trabajo de agente existente y empieza a usarlo inmediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por defecto",
      description:
        "Cada solicitud MCP se autentica con tokens de portador OAuth 2.1 y se autoriza contra alcances granulares. El mismo modelo de seguridad que REST API.",
      icon: "shield-check"
    }
  ]
}
---

## ¿Qué es el MCP?

El [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) es un estándar abierto para conectar asistentes de IA a herramientas y fuentes de datos externas. En lugar de crear integraciones personalizadas para cada asistente de codificación, expone un solo servidor MCP y cualquier cliente compatible puede usarlo.

El servidor MCP de Glossia ofrece a los agentes acceso directo al núcleo lingüístico de la plataforma: configuración de voz, gestión de glosario, administración de organizaciones y listado de proyectos.

## Herramientas disponibles

El servidor MCP expone 16 herramientas organizadas alrededor de los recursos con los que trabaja diariamente. Consulte la [referencia completa de herramientas](/docs/reference/mcp/tools) para los detalles de parámetros y uso.

**Cuentas y organizaciones** -- Liste sus cuentas, cree y gestione organizaciones, invite a miembros y controle el acceso. Los agentes pueden establecer toda la estructura del equipo a través de la conversación.

**Configuración de voz** -- Le y actualice las configuraciones de voz que controlan cómo Glossia genera y revisa el contenido. Ajuste el tono, la formalidad, el público objetivo y las sobrescritas por contexto sin salir de su editor.

**Gestión de glosario** -- Mantenga la coherencia del glosario en todo su contenido. Añada, actualice y versione las entradas del glosario para que los agentes siempre utilicen los términos adecuados.

**Proyectos** -- Liste y revise los proyectos en todas las organizaciones.

## Cómo funciona

Dirija su cliente MCP a `https://your-glossia-instance/mcp` y autenticúese con un token Bearer de OAuth. La [guía de configuración de MCP](/docs/reference/mcp/overview) recorre el flujo de conexión completo, incluido el registro dinámico de clientes y PKCE. El servidor utiliza el mismo sistema de autenticación y autorización que la [API REST](/features/rest-api), por lo que cualquier token que funcione para la API funciona para MCP.

A partir de ahí, su asistente de IA puede llamar a cualquiera de las 16 herramientas. Pregúntele "crear una organización llamada Acme" o "actualizar mi tono de voz a profesional" y el agente traduce tu intención en la llamada de herramienta correcta.

## Diseñado para flujos de trabajo de agentes

MCP no es solo una capa de conveniencia. Es la base para componer Glossia en tuberías de agentes más grandes. Un asistente de código puede leer su código base, detectar contenido no localizado, actualizar el glosario con nuevos términos, ajustar la configuración de voz para un contexto específico e iniciar una ejecución de localización, todo en una sola conversación.

Dado que el protocolo está normalizado, no está atado a ninguna cliente individual. Cambie entre Claude, Cursor o su propio agente personalizado sin cambiar una línea de configuración.
