%{
  title: "Visión general",
  summary:
    "Conecta los agentes de codificación a tus proyectos de Glossia mediante el Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servidor que permite a los agentes de codificación interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de codificación puede:

- Consultar el estado de traducción en sus proyectos
- Activar traducciones y revisiones
- Inspeccionar entradas de configuración y contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como un cliente OAuth mediante el endpoint de registro dinámico
3. Abre tu navegador para el inicio de sesión y consentimiento
4. Una vez que apruebas, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Agregar Glossia a un agente de codificación

### OpenAI Codex

Añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego, inicia sesión con OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para autenticación. Al aprobar, Codex almacena el token localmente y lo usa para sesiones futuras.

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

Añade el servidor a tu configuración MCP de Claude Code (`.claude/settings.json` o al archivo de configuración global):

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

Claude Code gestionará el flujo de OAuth automáticamente la primera vez que se conecte.

### Otros clientes MCP

Cualquier cliente que soporte la [Especificación de autorización de MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: HTTP transmisible
- **Descubrimiento**: El cliente debe soportar los metadatos del recurso protegido de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro dinámico de cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Client ID documentos de metadatos
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Apunta el cliente a tu URL de servidor MCP de Glossia y deja que maneje el descubrimiento y el registro automáticamente.

## Puntos finales de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP usan para inicializar el flujo OAuth:

| Punto final | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos de finalización, tipos de concesión admitidos, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (ámbitos, servidores de autorización) |

## Límites de tasa

Los puntos de finalización de OAuth imponen límites de tasa para prevenir abusos:

| Punto de finalización | Límite |
|---|---|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un lÍmite de tasa, el servidor responde HTTP 429 con un `Retry-After` encabezado.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El endpoint de registro dinámico solo acepta valores específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deberían enviar `"none"`, lo cual Glossia gestiona automáticamente recayendo en los métodos de autenticación predeterminados con aplicación de PKCE.

### "OAuth callback inválido" tras aprobar

Asegúrese de que su servidor Glossia esté en ejecución y accesible en la URL que configuró. El callback ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPN a veces pueden bloquear esto.

### El intercambio de tokens falla

Verifique que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar soporte para S256 para que funcione el PKCE. Glossia incluye esto por defecto.

### El agente no puede acceder al servidor

Para el desarrollo local, asegúrese de que el servidor Phoenix esté en ejecución (`mix phx.server`) y escuchando en el puerto esperado (predeterminado: 4050). El endpoint MCP debe ser accesible desde el proceso del agente.