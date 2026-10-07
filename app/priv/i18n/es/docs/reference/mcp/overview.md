%{
  title: "Visión general",
  summary:
    "Conecta agentes de codificación a tus proyectos de Glossia a través del Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---
glosia expone un [protocolo de contexto del modelo](https://modelcontextprotocol.io) (mcp) sirve para que los agentes de codificación interactúen con tus proyectos de localización. el servidor implementa oauth 2.1 con pkce y registro dinámico de cliente ([rfc 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo tanto, cualquier cliente compatible con mcp puede autenticarse sin una configuración manual de credenciales.

## qué proporciona el servidor mcp

una vez conectado, un agente de codificación puede listar cuentas y proyectos, crear proyectos, gestionar miembros y invitaciones de la organización, leer o actualizar ajustes de voz y glosario, y gestionar modelos y tokens de cuenta, sujeto a sus permisos.

el servidor no expone actualmente herramientas para iniciar traducciones o revisiones, ni para inspeccionar el estado de traducción por archivo. vea la [Referencia de herramientas](/docs/reference/mcp) para las herramientas disponibles.

## URL del servidor

Conectar al servicio alojado de Glossia en `https://glossia.ai/mcp`. Glossia ejecuta y mantiene este punto final; solo configuras la conexión en tu agente de codificación.

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización OAuth 2.1 con PKCE. No necesitas crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre Glossia a través de `https://glossia.ai/.well-known/oauth-authorization-server`
2. Se registra como un cliente OAuth a través del endpoint de registro dinámico
3. Abre tu navegador para iniciar sesión y dar consentimiento
4. Después de aprobar, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de codificación

### OpenAI Codex

Siguiendo la [Guía de conexión de Codex](https://developers.openai.com/codex/mcp), añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego, ejecuta el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para la autenticación. Después de aprobar, Codex guarda el token localmente y lo usa para las sesiones futuras.

Para verificar la conexión:

```bash
codex mcp list
```

### Claude Code

Añade el servidor alojado con el comando documentado en [la guía de conexión de Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Ejecutar `/mcp` Dentro de Claude Code y siguiendo el flujo de autenticación del navegador.

### Otros clientes MCP

Un cliente debe soportar el [flujo de autorización del Protocolo de Contexto del Modelo](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado por Glossia. La conexión requiere:

- **Transporte**: HTTP streaming
- **Descubrimiento**: El cliente debe soportar los metadatos de recursos protegidos de OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro de cliente dinámico ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Apunta el cliente a `https://glossia.ai/mcp` y déjalo gestionar el descubrimiento y el registro automáticamente.

## Endpoints de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para inicializar el flujo OAuth:

| Endpoint | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (endpoints, tipos de concesión admitidos, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos de recursos protegidos (scopes, servidores de autorización) |

## Límites de tasa

Los endpoints OAuth imponen límites de tasa para prevenir el abuso:

| Endpoint | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un límite de tasa, el servidor devuelve HTTP 429 con un `Retry-After` encabezado.

## Solución de problemas

### El registro falla con "invalid\_client\_metadata"

El endpoint de registro dinámico solo acepta específicos `token_endpoint_auth_method` valores. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo que Glossia gestiona automáticamente al volver a los métodos de autenticación predeterminados con el cumplimiento del PKCE.

### "Llamada de retorno OAuth no válida" tras la aprobación

Confirma que tu agente de codificación pueda alcanzar `https://glossia.ai`. La devolución de llamada ocurre en un puerto local que el agente de codificación abre temporalmente en tu computadora. Glossia sigue alojado; este escuchador local pertenece a tu agente. Los cortafuegos o redes privadas virtuales a veces pueden bloquear la devolución de llamada.

### El intercambio de tokens falla

Verifica que el `code_challenge_methods_supported` el campo está presente en los metadatos del servidor de autorización. El servidor debe anunciar el soporte de S256 para que PKCE funcione. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Verifique que el punto final configurado es `https://glossia.ai/mcp` y que su red permita que su agente de codificación pueda alcanzarlo. Si el servicio alojado permanece no disponible, contacte al soporte de Glossia.