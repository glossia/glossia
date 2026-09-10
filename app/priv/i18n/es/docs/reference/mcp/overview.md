%{
  title: "Introducción",
  summary:
    "Conecta los agentes de codificación a tus proyectos de Glossia a través del Model Context Protocol.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) (MCP) servidor que permite que los agentes de codificación interactúen con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro Dinámico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configurar credenciales manualmente.

## Lo que proporciona el servidor MCP

Una vez conectado, un agente de codificación puede:

- Consultar el estado de traducción en todos sus proyectos
- Iniciar traducciones y revisiones
- Inspeccionar la configuración y las entradas de contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar OAuth 2.1 de código de autorización con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de esta manera:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como un cliente OAuth mediante el endpoint de registro dinámico
3. Abre tu navegador para el inicio de sesión y el consentimiento
4. Después de aprobar, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadiendo Glossia a un agente de codificación

### OpenAI Codex

Añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

A continuación, ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para la autenticación. Tras aprobar, Codex guarda el token localmente y lo usa para las sesiones futuras.

Para verificar la conexión:

```bash
codex mcp list
```

Para el desarrollo local, reemplaza la URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Añade el servidor a las configuraciones de MCP de Claude Code (`.claude/settings.json` o al archivo de configuración global):

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code gestionará el flujo de OAuth automáticamente al conectarse por primera vez.

### Otros clientes MCP

Cualquier cliente que soporte el [especificación de autorización MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: HTTP transmisible
- **Descubrimiento**: El cliente debe admitir los metadatos de recurso protegido de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinámico de Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Documentos de metadatos del ID del cliente
- **Flujo de autorización**: Código de autorización con PKCE (S256)

Apunta el cliente a la URL de tu servidor Glossia MCP y deja que gestione el descubrimiento y el registro automáticamente.

## Puntos finales de descubrimiento

El servidor publica dos documentos de metadatos que los clientes de MCP utilizan para iniciar el flujo OAuth:

| Punto final | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos finales, tipos de concesión soportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (ámbitos, servidores de autorización) |

## Límites de tasa

Los puntos finales de OAuth aplican límites de tasa para prevenir abusos:

| Punto final | Límite |
|---|---|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un límite de tasa, el servidor responde con HTTP 429 con una `Retry-After` encabezado.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El punto final de registro dinámico solo acepta específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, que Glossia gestiona automáticamente recurriendo a los métodos de autenticación por defecto con la validación de PKCE.

### "Callback de OAuth inválido" después de aprobar

Asegúrese de que su servidor Glossia esté en ejecución y sea accesible en la URL que configuró. La devolución de llamada ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPNs pueden bloquear esto de vez en cuando.

### El intercambio de tokens falla

Compruebe que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe indicar el soporte S256 para que PKCE funcione. Glossia lo incluye por defecto.

### El agente no puede alcanzar el servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté en ejecución (`mix phx.server`) y escuchando en el puerto esperado (predeterminado: 4050). El punto final MCP debe ser accesible desde el proceso del agente.