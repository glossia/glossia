%{
  title: "Descripción general",
  summary: "Conecte agentes de programación a sus proyectos de Glossia mediante el Protocolo de Contexto de Modelo.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un servidor del [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) (MCP) que permite a los agentes de programación interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y registro dinámico de clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configurar credenciales manualmente.

## Qué ofrece el servidor MCP

Una vez conectado, un agente de programación puede:

- Consultar el estado de las traducciones de sus proyectos
- Iniciar traducciones y revisiones
- Examinar la configuración y las entradas de contenido
- Acceder al contexto del proyecto para ofrecer sugerencias de código más precisas

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No necesita crear clientes OAuth manualmente. El flujo funciona así:

1. El agente descubre su servidor mediante `/.well-known/oauth-authorization-server`
2. Se registra como cliente OAuth mediante el punto de conexión de registro dinámico
3. Abre su navegador para iniciar sesión y otorgar el consentimiento
4. Tras su aprobación, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de programación

### OpenAI Codex

Añada el servidor a su archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

A continuación, ejecute el inicio de sesión de OAuth:

```bash
codex mcp login glossia
```

Su navegador se abrirá para la autenticación. Tras la aprobación, Codex almacena el token localmente y lo utiliza en futuras sesiones.

Para verificar la conexión:

```bash
codex mcp list
```

Para el desarrollo local, sustituya la URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Añada el servidor a la configuración MCP de Claude Code (`.claude/settings.json` o el archivo de configuración global):

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

Claude Code gestionará automáticamente el flujo de OAuth cuando se conecte por primera vez.

### Otros clientes MCP

Funcionará cualquier cliente compatible con la [especificación de autorización de MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization). Los requisitos principales son:

- **Transporte**: HTTP transmisible
- **Descubrimiento**: El cliente debe ser compatible con los metadatos de recursos protegidos de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro dinámico de clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o documentos de metadatos del identificador de cliente
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Indique al cliente la URL de su servidor MCP de Glossia y permita que gestione automáticamente el descubrimiento y el registro.

## Puntos de conexión de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para iniciar el flujo de OAuth:

| Punto de conexión | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos de conexión, tipos de concesión admitidos y métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (ámbitos y servidores de autorización) |

## Límites de solicitudes

Los puntos de conexión de OAuth aplican límites de solicitudes para evitar abusos:

| Punto de conexión | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se supera un límite de solicitudes, el servidor devuelve HTTP 429 con una cabecera `Retry-After`.

## Resolución de problemas

### El registro falla con "invalid_client_metadata"

El punto de conexión de registro dinámico solo acepta valores `token_endpoint_auth_method` específicos. Los clientes públicos (la mayoría de los agentes de programación) deben enviar `"none"`, que Glossia gestiona automáticamente recurriendo a los métodos de autenticación predeterminados y aplicando PKCE.

### «Callback de OAuth no válido» después de aprobar

Asegúrese de que su servidor de Glossia esté en ejecución y sea accesible desde la URL configurada. El callback se realiza en un puerto local que el agente de programación abre temporalmente. A veces, los cortafuegos o las VPN pueden bloquearlo.

### Falla el intercambio de tokens

Compruebe que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar compatibilidad con S256 para que PKCE funcione. Glossia la incluye de forma predeterminada.

### El agente no puede acceder al servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté en ejecución (`mix phx.server`) y escuchando en el puerto esperado (predeterminado: 4050). El punto de conexión MCP debe ser accesible desde el proceso del agente.