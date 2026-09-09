%{
  title: "Visión general",
  summary:
    "Conecta agentes de codificación con tus proyectos de Glossia a través del Protocolo de Contexto de Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servidor que permite a los agentes de codificación interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro Dinámico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de codificación puede:

- Consultar el estado de traducción en todos sus proyectos
- Iniciar traducciones y revisiones
- Revisar configuraciones y entradas de contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No es necesario crear clientes OAuth manualmente. El flujo funciona así:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como un cliente OAuth a través del endpoint de registro dinámico
3. Abre tu navegador para iniciar sesión y otorgar el consentimiento
4. Tras tu aprobación, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de codificación

### OpenAI Codex

Añade el servidor al archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego, ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para autenticación. Tras aprobar, Codex almacena el token localmente y lo usa para futuras sesiones.

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

Añada el servidor a la configuración MCP de Claude Code (`.claude/settings.json` o al archivo de configuración global):

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

Cualquier cliente que soporte la [especificación de autorización de MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: HTTP transmisible
- **Descubrimiento**: El cliente debe soportar Metadatos de Recursos Protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro de Cliente Dinámico ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Client ID Metadatos Documentos
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Apunte el cliente a su URL del servidor MCP de Glossia y deje que maneje el descubrimiento y el registro automáticamente.

## Endpoints de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para inicializar el flujo OAuth:

| Endpoint | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos de finalización, tipos de concesión admitidos, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos de recurso protegido (alcances, servidores de autorización) |

## Límites de tasa

Los puntos de finalización OAuth imponen límites de tasa para evitar abusos:

| Punto de finalización | Límite |
|---|---|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede el límite de tasa, el servidor devuelve HTTP 429 con un `Retry-After` cabecera.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El endpoint de registro dinámico solo acepta determinados `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo cual Glossia gestiona automáticamente recurriendo a los métodos de autenticación predeterminados con el cumplimiento de PKCE.

### "Callback de OAuth inválido" después de aprobar

Asegúrese de que su servidor de Glossia esté en ejecución y sea accesible en la URL que configuró. La llamada de retorno ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPNs a veces pueden bloquear esto.

### El intercambio de tokens falla

Revise que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar el soporte para S256 para que funcione PKCE. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté en ejecución (`mix phx.server`) y escuchando en el puerto esperado (predeterminado: 4050). El endpoint de MCP debe ser accesible desde el proceso del agente.