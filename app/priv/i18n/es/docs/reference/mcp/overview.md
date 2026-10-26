%{
  title: "Visión general",
  summary:
    "Conecta agentes de codificación a tus proyectos de Glossia a través del Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---

Glossia expone un servidor [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) (MCP) que permite a los agentes de código interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de cliente dinámico ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Qué proporciona el servidor MCP

Una vez conectado, un agente de código puede enumerar cuentas y proyectos, crear proyectos, gestionar miembros de la organización e invitaciones, leer o actualizar configuraciones de voz y glosario, y gestionar modelos de cuenta y tokens, sujeto a sus permisos.

El servidor actualmente no expone herramientas para iniciar traducciones o revisiones, ni para inspeccionar el estado de traducción por archivo. Consulte la [referencia de herramientas](/docs/reference/mcp) para las herramientas disponibles.

## URL del servidor

Conéctese al servicio alojado de Glossia en `https://glossia.ai/mcp`. Glossia ejecuta y mantiene este extremo; solo configura la conexión en su agente de código.

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de código de autorización con PKCE de OAuth 2.1. No es necesario crear clientes OAuth manualmente. El flujo funciona así:

1. El agente descubre Glossia a través del `https://glossia.ai/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como cliente OAuth mediante el extremo de registro dinámico
3. Abre tu navegador para iniciar sesión y dar consentimiento
4. Tras aprobar, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Agregar Glossia a un agente de código

### OpenAI Codex

Siguiendo la [Guía de conexión de Codex](https://developers.openai.com/codex/mcp), añade el servidor a tu archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Luego ejecuta la autenticación OAuth:

```bash
codex mcp login glossia
```

Tu navegador se abrirá para autenticación. Tras aprobar, Codex almacena el token localmente y lo usa para las sesiones futuras.

Para verificar la conexión:

```bash
codex mcp list
```

### Claude Code

Añade el servidor alojado con el comando documentado en la [Guía de conexión de Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Ejecuta `/mcp` dentro de Claude Code y sigue el flujo de autenticación del navegador.

### Otros clientes MCP

Un cliente debe soportar el [flujo de autorización del Protocolo de Contexto del Modelo](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado por Glossia. La conexión requiere:

- **Transporte**: HTTP con flujo
- **Descubrimiento**: El cliente debe soportar metadatos de recurso protegido OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro de cliente dinámico ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flujo de autenticación**: Código de autorización con PKCE (S256)

Apunte el cliente hacia `https://glossia.ai/mcp` y permítale que maneje el descubrimiento y el registro automáticamente.

## Extremos de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para inicializar el flujo OAuth

| Extremo | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (extremos, tipos de concesión admitidos, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos de recursos protegidos (alcances, servidores de autorización) |

## Límites de tasa

Los extremos OAuth aplican límites de tasa para evitar abusos:

| Extremo | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un límite de tasa, el servidor responde con HTTP 429 y un encabezado `Retry-After`.

## Solución de problemas

### El registro falla con "invalid_client_metadata"

El extremo de registro dinámico solo acepta valores `token_endpoint_auth_method` específicos. Los clientes públicos (la mayoría de los agentes de código) deben enviar `"none"`, lo cual Glossia gestiona automáticamente recayendo en métodos de autenticación predeterminados con aplicación de PKCE.

### "Invalid OAuth callback" después de aprobar

Asegúrate de que tu agente de código pueda alcanzar `https://glossia.ai`. La devolución de llamada ocurre en un puerto local que el agente de código abre temporalmente en tu computadora. Glossia sigue alojado; esta escucha local pertenece a tu agente. Los cortafuegos o las redes privadas virtuales a veces pueden bloquear la devolución de llamada.

### El intercambio de token falla

Verifica que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar soporte S256 para que funcione el PKCE. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor

Verifica que el extremo configurado sea `https://glossia.ai/mcp` y que tu red permita que tu agente de código lo alcance. Si el servicio alojado permanece inaccesible, contacta al soporte de Glossia.
