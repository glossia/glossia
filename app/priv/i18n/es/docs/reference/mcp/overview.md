%{
  title: "Visión general",
  summary:
    "Conecte los agentes de codificación a sus proyectos de Glossia mediante el Protocolo de Contexto de Modelo.",
  category: "referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servidor que permite a los agentes de programación interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de Cliente Dinámico ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de programación puede:

- Consultar el estado de traducción en sus proyectos
- Iniciar traducciones y revisiones
- Revisar la configuración y las entradas de contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar OAuth 2.1 de código de autorización con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra como cliente OAuth mediante el punto final de registro dinámico
3. Abre tu navegador para iniciar sesión y dar consentimiento
4. Una vez que apruebas, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadiendo Glossia a un agente de codificación

### OpenAI Codex

Añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Se abrirá tu navegador para la autenticación. Tras aprobar, Codex guarda el token localmente y lo usa en sesiones futuras.

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

Agrega el servidor a tu configuración MCP de Claude Code (`.claude/settings.json` o al archivo de configuración global):

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

Cualquier cliente que soporte la [especificación de autorización MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: Streamable HTTP
- **Descubrimiento**: El cliente debe soportar el Metadato de Recursos Protegidos de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinámico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Documentos de metadatos de Client ID
- **Flujo de autorización**: Código de autorización con PKCE (S256)

Dirija la URL de su servidor MCP de Glossia al cliente y permítale que gestione el descubrimiento y el registro automáticamente.

## Puntos finales de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para iniciar el flujo de OAuth:

| Endpoint | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos finales, tipos de concesión compatibles, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (alcances, servidores de autorización) |

## Límites de tasa

Los puntos finales OAuth imponen límites de tasa para evitar abusos:

| Punto final | Límite |
|---|---|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un límite de tasa, el servidor devuelve HTTP 429 con un `Retry-After` cabecera.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El endpoint de registro dinámico solo acepta valores específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo cual Glossia gestiona automáticamente al recurrir a los métodos de autenticación predeterminados con la aplicación de PKCE.

### "Llamada de retorno OAuth inválida" después de aprobar

Asegúrese de que su servidor de Glossia esté ejecutándose y sea accesible en la URL que configuró. La devolución de llamada ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPNs pueden a veces bloquear esto.

### El canje de tokens falla

Verifique que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar el soporte S256 para que funcione PKCE. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté ejecutándose (`mix phx.server`) y escuchando en el puerto esperado (predeterminado: 4050). El endpoint MCP debe ser accesible desde el proceso del agente.