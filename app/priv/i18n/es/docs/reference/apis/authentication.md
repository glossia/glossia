%{
  title: "Autenticación y autorización",
  summary: "Cómo Glossia autentica usuarios y autoriza el acceso a la API.",
  category: "Referencia",
  subcategory: "APIs",
  order: 1
}
---
## Métodos de autenticación

Glossia admite dos métodos de autenticación según el contexto.

### Sesiones de navegador

Al iniciar sesión a través de la interfaz web, Glossia utiliza autenticación basada en sesiones. Te autentificas mediante un proveedor de terceros (GitHub o GitLab) usando el [Assent](https://github.com/pow-auth/assent) librería. Tras un inicio de sesión exitoso, se establece una cookie de sesión y se utiliza para las solicitudes posteriores.

### Tokens Bearer (OAuth 2.1)

Para el acceso a la API (como desde la CLI u otras herramientas), Glossia implementa OAuth 2.1 con el flujo de código de autorización y PKCE. Los clientes obtienen un token Bearer y lo incluyen en el `Authorization` cabecera:

    Authorization: Bearer <access_token>

## Flujo OAuth 2.1

### 1\. Registro dinámico de clientes

Los clientes se registran llamando `POST /oauth/register` con sus metadatos. Esto sigue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

El servidor devuelve `client_id` y `client_secret`.

### 2\. Solicitud de autorización

El cliente redirige al usuario a `/oauth/authorize` con parámetros PKCE:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE es requerido para todos los clientes.** Solo el `S256` método de desafío está soportado.

### 3\. Intercambio de token

Después de que el usuario apruebe, el cliente intercambia el código de autorización por tokens en `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

La respuesta incluye un token de acceso y opcionalmente un token de actualización.

### 4\. Renovación de token

Cuando un token de acceso caduca, utilice el token de actualización:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el `object:action` patrón.

| Alcance | Descripción |
|-------|-------------|
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar cuentas de organización a las que tienes acceso |
| `organization:read` | Leer detalles de la organización (y listar tus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de la organización |
| `members:read` | Leer miembros de la organización y las invitaciones |
| `members:write` | Gestionar miembros de la organización y las invitaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas del proyecto |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas del glosario |
| `glossary:write` | Crear o actualizar entradas de glosario |
| `glossary:admin` | Gestionar la configuración del glosario |

## Modelo de autorización

Glossia impone **dos capas** para la API REST y el servidor MCP:

1. **Verificación de alcance**: el token de acceso debe incluir el requerido `object:action` alcance.
2. **Política de nivel de recurso**: el usuario actual debe estar autorizado para el recurso específico mediante `Glossia.Policy`.

Los alcances representan la *máximo* capacidad de un token. El sistema de políticas impone la *real* permiso para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización propietaria del recurso |
| `public_account` | La cuenta es pública (solo lectura) |

### Permisos de rol

| Alcance | Yo | Miembro de la organización | Administrador de la organización | Cuenta pública |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Sí | Sí | | |
| `user:write` | Sí | | | |
| `account:read` | | Sí | Sí | Sí |
| `organization:read` | | Sí | Sí | |
| `organization:write` | | | Sí | |
| `organization:delete` | | | Sí | |
| `organization:admin` | | | Sí | |
| `members:read` | | Sí | Sí | |
| `members:write` | | | Sí | |
| `project:read` | | Sí | Sí | Sí |
| `project:write` | | | Sí | |
| `project:admin` | | | Sí | |
| `project:delete` | | | Sí | |
| `voice:read` | | Sí | Sí | Sí |
| `voice:write` | | | Sí | |
| `voice:admin` | | | Sí | |
| `glossary:read` | | Sí | Sí | |
| `glossary:write` | | | Sí | |
| `glossary:admin` | | | Sí | |

## Endpoints de descubrimiento

Glossia publica metadatos en URLs estándar y bien conocidas para que los clientes puedan descubrir endpoints automáticamente.

### Metadatos del Servidor de Autorización OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Devuelve el emisor, endpoints, alcances soportados, tipos de concesión y métodos de desafío de código.

### Metadatos de Recursos Protegidos (RFC 9728)

    GET /.well-known/oauth-protected-resource

Devuelve el identificador de recurso, servidores de autorización, alcances soportados y métodos de portador.

## Limitación de tasa

Los endpoints de OAuth tienen limitación de tasa por dirección IP:

| Endpoint | Límite |
|----------|-------|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |

Cuando hay limitación de tasa, el servidor devuelve HTTP 429 (Demasiadas solicitudes).