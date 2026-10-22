%{
  title: "Introducción",
  summary:
    "Conecta los agentes de codificación con tus proyectos de Glossia a través del Protocolo de Contexto del Modelo.",
  category: "Referencia",
  subcategory: "mcp",
  order: 1
}
---

Glossia expone un [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) (MCP) que permite a los agentes de código interactuar con sus proyectos de localización. El servidor implementa OAuth 2.1 con PKCE y Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), por lo que cualquier cliente compatible con MCP puede autenticarse sin configuración manual de credenciales.

## Lo que proporciona el servidor MCP

Una vez conectada, un agente de código puede listar cuentas y proyectos, crear proyectos, gestionar miembros y invitaciones de la organización, leer o actualizar la configuración de voz y glosario, y gestionar modelos de cuenta y tokens, sujeto a sus permisos.

El servidor no expone actualmente herramientas para iniciar traducciones o revisiones, ni para inspeccionar el estado de traducción por archivo. Consulte la [referencia de herramientas](/docs/reference/mcp) para las herramientas disponibles.

## URL del servidor

Conéctese al servicio alojado de Glossia en `https://glossia.ai/mcp`. Glossia ejecuta y mantiene este punto final; solo configura la conexión en su agente de código.

## Flujo de autenticación

El servidor MCP utiliza el flujo estándar de autorización OAuth 2.1 con código y PKCE. No necesita crear clientes OAuth manualmente. El flujo funciona de la siguiente manera:

1. El agente descubre Glossia a través de `https://glossia.ai/.well-known/oauth-authorization-server`
2. Se registra a sí mismo como un cliente OAuth a través del endpoint de registro dinámico
3. Abre su navegador para iniciar sesión y dar consentimiento
4. Después de que apruebe, el agente recibe un token de acceso y lo adjunta a todas las solicitudes MCP

## Añadir Glossia a un agente de código

### OpenAI Codex

Siga la [guía de conexión de Codex](https://developers.openai.com/codex/mcp) y añada el servidor al archivo de configuración de Codex en `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

A continuación, ejecute el inicio de sesión OAuth:

```bash
codex mcp login glossia
```

Su navegador se abrirá para la autenticación. Después de aprobar, Codex almacena el token localmente y lo usa en futuras sesiones.

Para verificar la conexión:

```bash
codex mcp list
```

### Claude Code

Añada el servidor alojado con el comando documentado en [la guía de conexión de Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Ejecútese `/mcp` dentro de Claude Code y siga el flujo de autenticación del navegador.

### Otros clientes MCP

Un cliente debe admitir el [flujo de autorización del Protocolo de Contexto del Modelo](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implementado por Glossia. La conexión requiere:

- **Transporte**: HTTP en streaming
- **Descubrimiento**: El cliente debe admitir los metadatos de recursos protegidos OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registro**: Registro de Clientes Dinámicos ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flujo de autorización**: Código de autorización con PKCE (S256)

Dirija el cliente a `https://glossia.ai/mcp` y déjelo gestionar el descubrimiento y el registro automáticamente.

## Puntos finales de descubrimiento

El servidor publica dos documentos de metadatos que los clientes MCP utilizan para iniciar el flujo OAuth:

| Punto final | Descripción |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadatos del servidor de autorización (puntos finales, tipos de concesión admitidos, métodos PKCE) |
| `/.well-known/oauth-protected-resource` | Metadatos de recursos protegidos (ámbitos, servidores de autorización) |

## Límites de tasa

Los puntos finales OAuth aplican límites de velocidad para prevenir abusos:

| Punto final | Límite |
|---|---|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |

Cuando se excede un límite de tasa, el servidor devuelve HTTP 429 con un `Retry-After` encabezado.

## Solución de problemas

### El registro falla con "invalid_client_metadata"

El endpoint de registro dinámico solo acepta valores `token_endpoint_auth_method` específicos. Los clientes públicos (la mayoría de los agentes de codificación) deben enviar `"none"`, lo que Glossia gestiona automáticamente volviendo a los métodos de autenticación predeterminados con aplicación de PKCE.

### "Callback de OAuth no válido" después de aprobar

Confirme que su agente de código puede alcanzar `https://glossia.ai`. El callback ocurre en un puerto local que el agente de código abre temporalmente en su computadora. Glossia sigue alojado; este escuchador local pertenece a su agente. Los firewalls o las redes privadas virtuales a veces pueden bloquear el callback.

### El intercambio de tokens falla

Verifique que el campo `code_challenge_methods_supported` esté presente en los metadatos del servidor de autorización. El servidor debe anunciar el soporte para S256 para que PKCE funcione. Glossia incluye esto por defecto.

### El agente no puede alcanzar el servidor.

Verifique que el punto final configurado sea `https://glossia.ai/mcp` y que su red permita a su agente de código alcanzarlo. Si el servicio alojado permanece no disponible, contacte el soporte de Glossia.
