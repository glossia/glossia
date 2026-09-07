%{
  title: "Visión general",
  summary:
    "Conecta los agentes de programación a tus proyectos Glossia mediante el Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un servidor [Model Context Protocol](https://modelcontextprotocol.io) (MCP) que permite a los agentes de codificación interactuar con tus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de codificación puede:

- Consultar el estado de traducción de todos sus proyectos
- Activar traducciones y revisiones
- Inspeccionar entradas de configuración y contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo de autorización de código estándar OAuth 2.1 con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona así:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra como un cliente OAuth mediante el punto de extremo de registro dinámico
3. Abre tu navegador para iniciar sesión y dar consentimiento
4. Después de que apruebas, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Agregar Glossia a un agente de codificación

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

Tu navegador se abrirá para autenticarse. Después de aprobar, Codex guarda el token localmente y lo utiliza para futuras sesiones.

Para verificar la conexión:

```bash
codex mcp list
```

Para desarrollo local, reemplaza la URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Añade el servidor a la configuración MCP de Claude Code (`.claude/settings.json` o el archivo de configuración global):

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

Claude Code manejará el flujo OAuth automáticamente cuando se conecte por primera vez.

### Otros clientes MCP

Cualquier cliente que soporte la [especificación de autorización MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: HTTP en streaming
- **Descubrimiento**: El cliente debe soportar Metadatos de Recursos Protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Documentos de Metadatos de ID de Cliente
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Apunta tu cliente a la URL de tu servidor MCP de Glossia y deja que gestione el descubrimiento y el registro automáticamente.

## Puntos de extremo de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para iniciar el flujo OAuth:

| Punto de extremo | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos de extremo, tipos de concesión compatibles, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (alcances, servidores de autorización) |

## Límites de tasa

Los puntos de extremo OAuth imponen límites de tasa para evitar abusos:

| Punto de extremo | Límite |
|---|---|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 peticiones por minuto |

Cuando se supera un límite de tasa, el servidor devuelve HTTP 429 con el encabezado `Retry-After`.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El punto de extremo de registro dinámico solo acepta valores específicos de `token_endpoint_auth_method`. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo que Glossia gestiona automáticamente retomando los métodos de autenticación predeterminados con la aplicación de PKCE.

### "Invalid OAuth callback" después de aprobar

Asegúrese de que su servidor Glossia esté en ejecución y sea accesible en la URL que configuró. El callback ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPNs pueden bloquear esto ocasionalmente.

### El intercambio de tokens falla

Verifique que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe exponer el soporte S256 para que PKCE funcione. Glossia lo incluye por defecto.

### El agente no puede acceder al servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté en ejecución (`mix phx.server`) y escuche en el puerto esperado (predeterminado: 4050). El endpoint MCP debe ser accesible desde el proceso del agente.