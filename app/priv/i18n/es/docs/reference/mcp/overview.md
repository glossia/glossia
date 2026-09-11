%{
  title: "Resumen",
  summary:
    "Conecta agentes de código a tus proyectos de Glossia a través del Protocolo de Contexto del Modelo.",
  category: "referencia",
  subcategory: "mcp",
  order: 1
}
---
Glossia expone un [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servidor que permite a los agentes de codificación interactuar con tus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro dinámico de clientes ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Lo que ofrece el servidor MCP

Una vez conectado, un agente de codificación puede:

- Consultar el estado de traducción en tus proyectos
- Iniciar traducciones y revisiones
- Inspeccionar entradas de configuración y contenido
- Acceder al contexto del proyecto para sugerencias de código más inteligentes

## URL del servidor

| Entorno | URL |
|---|---|
| Producción | `https://glossia.ai/mcp` |
| Desarrollo local | `http://localhost:4050/mcp` |

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre tu servidor a través `/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como cliente OAuth a través del punto final de registro dinámico
3. Abre tu navegador para el inicio de sesión y el consentimiento
4. Después de aprobarlo, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de código

### OpenAI Codex

Agrega el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para autenticación. Tras aprobar, Codex guarda el token localmente y lo utiliza para futuras sesiones.

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

Añade el servidor a tus ajustes MCP de Claude Code (`.claude/settings.json` o el archivo de configuración global):

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
- **Descubrimiento**: El cliente debe soportar Metadatos de Recursos Protegidos de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro Dinámico del Cliente ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) o documentos de metadatos del Client ID
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

: Apunta el cliente a tu URL del servidor MCP de Glossia y déjale que gestione automáticamente el descubrimiento y el registro.

## Puntos finales de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para iniciar el flujo OAuth:

| Punto final | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos finales, tipos de concesión soportados, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos del recurso protegido (alcances, servidores de autorización) |

## Límites de tasa

Los puntos finales OAuth imponen límites de tasa para prevenir el abuso:

| Punto final | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se supera un límite de tasa, el servidor devuelve HTTP 429 con una `Retry-After` cabecera.

## Solución de problemas

### El registro falla con \\"invalid\_client\_metadata\\"

El endpoint de registro dinámico solo acepta específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo cual Glossia gestiona automáticamente recurriendo a los métodos de autenticación predeterminados con aplicación de PKCE.

### "Retorno de OAuth inválido" después de aprobar

Asegúrese de que su servidor de Glossia esté ejecutándose y sea accesible en la URL que configuró. El callback ocurre en un puerto local que el agente de codificación abre temporalmente. A veces los firewalls o las VPNs pueden bloquear esto.

### Fallo en el intercambio de tokens

Verifique que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe ofrecer soporte S256 para que funcione PKCE. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Para desarrollo local, asegúrese de que el servidor de Phoenix esté ejecutándose (`mix phx.server`) y escuchando en el puerto esperado (por defecto: 4050). El punto final de MCP debe ser accesible desde el proceso del agente.