%{
  title: "Vista general",
  summary:
    "Conecta los agentes de codificación a tus proyectos de Glossia mediante el Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) (MCP) servidor que permite a los agentes de programación interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de programación puede:

- Consultar el estado de traducción en sus proyectos
- Iniciar traducciones y revisiones
- Inspeccionar configuración y entradas de contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre tu servidor a través de `/.well-known/oauth-authorization-server`
2. Se registra como cliente OAuth mediante el endpoint de registro dinámico
3. Abre tu navegador para iniciar sesión y dar consentimiento
4. Una vez que apruebas, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de programación

### OpenAI Codex

Añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego, ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para la autenticación. Tras la aprobación, Codex almacena el token localmente y lo utiliza para sesiones futuras.

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

Claude Code gestionará el flujo OAuth automáticamente cuando se conecte por primera vez.

### Otros clientes MCP

Cualquier cliente que soporte la [especificación de autorización MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funcionará. Los requisitos clave son:

- **Transporte**: HTTP transmisible
- **Descubrimiento**: El cliente debe soportar Metadatos de Recursos Protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinámico de Clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o Documentos de Metadatos del ID del Cliente
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

, Dirige el cliente a tu URL de servidor MCP de Glossia y déjalo manejar el descubrimiento y el registro automáticamente.

## Endpoints de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para inicializar el flujo OAuth:

| Endpoint | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos finales, tipos de concesión compatibles, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos de recursos protegidos (ámbitos, servidores de autorización) |

## Límites de tasa

Los puntos finales de OAuth imponen límites de tasa para evitar abusos:

| Punto final | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede el límite de tasa, el servidor devuelve HTTP 429 con un `Retry-After` encabezado.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El endpoint de registro dinámico solo acepta específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo cual Glossia gestiona automáticamente al recurrir a los métodos de autenticación predeterminados con aplicación de PKCE.

### "Inválido OAuth callback" después de aprobar

Asegúrate de que tu servidor de Glossia esté ejecutándose y sea accesible en la URL que configuraste. La llamada de retorno ocurre en un puerto local que el agente de codificación abre temporalmente. Los firewalls o las VPNs pueden a veces bloquear esto.

### El intercambio de tokens falla

Comprueba que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar soporte S256 para que funcione PKCE. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Para el desarrollo local, asegúrate de que el servidor de Phoenix esté ejecutándose (`mix phx.server`) y escuchando en el puerto esperado (default: 4050). El endpoint de MCP debe ser accesible desde el proceso del agente.